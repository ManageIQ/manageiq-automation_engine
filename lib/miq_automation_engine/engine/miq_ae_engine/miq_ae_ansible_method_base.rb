module MiqAeEngine
  class MiqAeAnsibleMethodBase
    include AnsibleExtraVarsMixin

    ANSIBLE_STATS_PREFIX = 'ansible_stats_'.freeze
    ANSIBLE_STATS_PREFIX_LEN = ANSIBLE_STATS_PREFIX.size
    METHOD_KEY_SUFFIX = "_ansible_method_task_id".freeze
    MIN_RETRY_INTERVAL = 1.minute
    VALID_ANSIBLE_VARIABLE_NAME_REGEX = /\A[_a-zA-Z][_a-zA-Z0-9]*\z/

    def self.cleanup(workspace)
      aw_guid = workspace.persist_state_hash.delete('automate_workspace_guid')
      AutomateWorkspace.find_by(:guid => aw_guid).try(:delete)
      workspace.persist_state_hash.delete_if { |key, _| key.to_s.match(/#{METHOD_KEY_SUFFIX}$/) }
    end

    def self.ansible_stats_from_hash(hash)
      hash.each_with_object({}) do |(attr, val), obj|
        obj[attr[ANSIBLE_STATS_PREFIX_LEN..-1]] = val if attr.start_with?(ANSIBLE_STATS_PREFIX)
      end
    end

    def initialize(aem, obj, inputs)
      @workspace = obj.workspace
      @inputs    = inputs
      @aem       = aem
      @ae_object = obj
    end

    def run
      if @workspace.persist_state_hash[method_key].present?
        task_id = @workspace.persist_state_hash[method_key]
        @aw = AutomateWorkspace.find_by(:guid => @workspace.persist_state_hash['automate_workspace_guid'])
        check_task_status(task_id)
      else
        execute
      end
    end

    private

    def execute
      raise NotImplementedError, _("execute must be implemented in a subclass")
    end

    def running_in_state_machine?
      @workspace.root['ae_state_started'].present?
    end

    def process_result(task)
      @aw.reload
      @workspace.update_workspace(@aw.output) if @aw.output
      ansible_stats_from_task(task).each do |k, v|
        @workspace.persist_state_hash["#{ANSIBLE_STATS_PREFIX}#{k}"] = v
        begin
          update_object_with_stats(k, v)
        rescue StandardError => err
          $miq_ae_logger.error("Failed to update object with Ansible set_stats data [#{k} = #{v}]: #{err.message}")
        end
      end
      reset
    end

    def ansible_stats_from_task(task)
      task&.context_data&.dig(:ansible_runner_stdout, -1, 'event_data', 'artifact_data') || {}
    end

    # key in the format of:
    #   miq_provision__options__var1
    #   miq_provision__status
    #   service_var__var1
    def update_object_with_stats(key, value)
      unless valid_ansible_variable_name?(key)
        raise _("Ansible variables must start with a letter or underscore character, and contain only letters, numbers and underscores: [%{var}]") % {:var => key}
      end

      attrs = key.to_s.split("__")
      return if attrs.size < 2

      obj_name, attr, *args = *attrs
      return service_var_with_stats(attr, value) if obj_name == 'service_var'

      object = @workspace.current[obj_name] || @workspace.root[obj_name]
      $miq_ae_logger.info("  object: #{object.inspect}")
      raise _("Object not found: [%{obj_name}]") % {:obj_name => obj_name} if object.blank?
      raise _("Invalid attribute [%{attr}] for %{object}") % {:attr => attr, :object => object} unless object.respond_to?(attr)

      args.present? ? object.object_send(attr).store_path(*args, value) : object.object_send("#{attr}=", value)
      object.object_send(:save!)
    end

    def service_var_with_stats(key, value)
      object = @workspace.current['service'] || @workspace.root['service']
      raise _("Object update failed - service object not found for: [service_var__%{key} = %{value}]") % {:key => key, :value => value} if object.blank?

      object.root_service.set_service_vars_option("#{ANSIBLE_STATS_PREFIX}#{key}", value)
    end

    def valid_ansible_variable_name?(var)
      VALID_ANSIBLE_VARIABLE_NAME_REGEX.match?(var)
    end

    def reset
      @aw.delete
      self.class.cleanup(@workspace)
    end

    def wait_for_method(task_id)
      task = MiqTask.wait_for_taskid(task_id)
      raise MiqAeException::Error, task.message unless task.status == "Ok"
      process_result(task)
    ensure
      reset
    end

    def check_task_status(task_id)
      task = MiqTask.find(task_id)
      raise MiqAeException::Error, "Task id #{task_id} not found" unless task
      return mark_for_retry(task_id) unless task.state == MiqTask::STATE_FINISHED
      post_process_status(task)
    end

    def post_process_status(task)
      unless task.status == MiqTask::STATUS_OK
        @workspace.root['ae_result'] = 'error'
        reset
        raise MiqAeException::Error, task.message
      end

      @workspace.root['ae_result'] = 'ok'
      process_result(task)
    end

    def mark_for_retry(task_id)
      @workspace.root['ae_result'] = 'async_launch'
      @workspace.root['ae_retry_interval'] = retry_interval
      @workspace.persist_state_hash['automate_workspace_guid'] = @aw.guid
      @workspace.persist_state_hash[method_key] = task_id
      $miq_ae_logger.info("Setting State Machine Auto Retry Interval: #{@workspace.root['ae_retry_interval']}")
    end

    def ttl
      @aem.options[:execution_ttl].to_i.minutes
    end

    def max_retries
      @workspace.root['ae_state_max_retries'].to_i
    end

    def retry_interval
      interval = ttl.positive? && max_retries.positive? ? ttl / max_retries : MIN_RETRY_INTERVAL
      interval > MIN_RETRY_INTERVAL ? interval : MIN_RETRY_INTERVAL
    end

    def method_manageiq_env
      {
        'automate_workspace' => @aw.href_slug
      }.merge(manageiq_env(@workspace.ae_user, @workspace.ae_user.current_group, miq_request_task))
    end

    def method_key
      @method_key_value ||= "#{@aem.name}#{METHOD_KEY_SUFFIX}".gsub(/\s+/, "")
    end

    def serialize_workspace
      {'objects'           => @workspace.hash_workspace,
       'method_parameters' => MiqAeEngine::MiqAeReference.encode(@inputs),
       'current'           => current_info,
       'state_vars'        => MiqAeEngine::MiqAeReference.encode(@workspace.persist_state_hash)}
    end

    def current_info
      list = %w(namespace class instance message method)
      list.each.with_object({}) { |m, hash| hash[m] = @workspace.send("current_#{m}".to_sym) }
    end

    def build_options_hash
      @aem.options.tap do |config_info|
        config_info[:extra_vars] = MiqAeEngine::MiqAeReference.encode(@inputs.merge(ansible_stats_from_ws))
        config_info[:extra_vars][:manageiq] = method_manageiq_env
        config_info[:extra_vars][:manageiq_connection] = manageiq_connection_env(@workspace.ae_user)
      end
    end

    def ansible_stats_from_ws
      self.class.ansible_stats_from_hash(@workspace.persist_state_hash)
    end

    def miq_request_task
      result = nil
      if @workspace.root['vmdb_object_type']
        vmdb_obj = @workspace.root[@workspace.root['vmdb_object_type']]
        if vmdb_obj.kind_of?(MiqAeMethodService::MiqAeServiceMiqRequestTask)
          result = vmdb_obj
        end
      end
      result
    end
  end
end
