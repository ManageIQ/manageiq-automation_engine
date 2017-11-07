module MiqAeEngine
  class MiqAePlaybookMethod
    PLAYBOOK_CLASS = ManageIQ::Providers::EmbeddedAnsible::AutomationManager::Playbook
    METHOD_KEY_SUFFIX = "_ansible_method_task_id".freeze
    MIN_RETRY_INTERVAL = 1.minute

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

    def self.cleanup(workspace)
      aw_guid = workspace.persist_state_hash.delete('automate_workspace_guid')
      AutomateWorkspace.find_by(:guid => aw_guid).try(:delete)
      workspace.persist_state_hash.delete_if { |key, _| key.to_s.match(/#{METHOD_KEY_SUFFIX}$/) }
    end

    private

    def execute
      @aw = AutomateWorkspace.create(:input  => serialize_workspace,
                                     :user   => @workspace.ae_user,
                                     :tenant => @workspace.ae_user.current_tenant)
      playbook_options = build_options_hash
      $miq_ae_logger.info("Playbook Method passing options: #{playbook_options.inspect}")
      begin
        playbook = PLAYBOOK_CLASS.find(playbook_options[:playbook_id])
        $miq_ae_logger.info("Calling playbook.run with playbook: #{playbook.inspect}")
        task_id = playbook.run(playbook_options)
      rescue => err
        $miq_ae_logger.error("Playbook Method Ended with error #{err.message}")
        reset
        raise MiqAeException::AbortInstantiation, err.message
      end

      running_in_state_machine? ? check_task_status(task_id) : wait_for_method(task_id)
    end

    def running_in_state_machine?
      @workspace.root['ae_state_started'].present?
    end

    def process_result
      @aw.reload
      @workspace.update_workspace(@aw.output) if @aw.output
      reset
    end

    def reset
      @aw.delete
      self.class.cleanup(@workspace)
    end

    def wait_for_method(task_id)
      task = MiqTask.wait_for_taskid(task_id)
      raise MiqAeException::Error, task.message unless task.status == "Ok"
      process_result
    ensure
      reset
    end

    def check_task_status(task_id)
      task = MiqTask.find(task_id)
      raise MiqAeException::Error, "Task id #{task_id} not found" unless task
      if task.state == MiqTask::STATE_FINISHED
        if task.status == MiqTask::STATUS_OK
          @workspace.root['ae_result'] = 'ok'
          process_result
        else
          @workspace.root['ae_result'] = 'error'
          reset
          raise MiqAeException::Error, task.message
        end
      else
        mark_for_retry(task_id)
      end
    end

    def mark_for_retry(task_id)
      @workspace.root['ae_result'] = 'retry'
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

    def manageiq_env
      {
        'api_token'          => api_token,
        'api_url'            => api_url,
        'user'               => @workspace.ae_user.href_slug,
        'group'              => @workspace.ae_user.current_group.href_slug,
        'automate_workspace' => @aw.href_slug,
        'X_MIQ_Group'        => @workspace.ae_user.current_group.description
      }.merge(miq_request_task_url)
    end

    def manageiq_connection_env
      {
        'token'       => api_token,
        'url'         => api_url,
        'X_MIQ_Group' => @workspace.ae_user.current_group.description
      }
    end

    def method_key
      @method_key_value ||= "#{@aem.name}#{METHOD_KEY_SUFFIX}".gsub(/\s+/, "")
    end

    def serialize_workspace
      {'objects'           => @workspace.hash_workspace,
       'method_parameters' => MiqAeReference.encode(@inputs),
       'current'           => current_info,
       'state_vars'        => MiqAeReference.encode(@workspace.persist_state_hash)}
    end

    def current_info
      list = %w(namespace class instance message method)
      list.each.with_object({}) { |m, hash| hash[m] = @workspace.send("current_#{m}".to_sym) }
    end

    def build_options_hash
      @aem.options.tap do |config_info|
        config_info[:extra_vars] = MiqAeReference.encode(@inputs)
        config_info[:extra_vars][:manageiq] = manageiq_env
        config_info[:extra_vars][:manageiq_connection] = manageiq_connection_env
        config_info[:hosts] = resolved_hosts
      end
    end

    def api_token
      @api_token ||= Api::UserTokenService.new.generate_token(@workspace.ae_user.userid, 'api')
    end

    def api_url
      @api_url ||= MiqRegion.my_region.remote_ws_url
    end

    def miq_request_task_url
      result = {}
      if @workspace.root['vmdb_object_type']
        vmdb_obj = @workspace.root[@workspace.root['vmdb_object_type']]
        if vmdb_obj.kind_of?(MiqAeMethodService::MiqAeServiceMiqRequestTask)
          result['request_task'] = "#{vmdb_obj.miq_request.href_slug}/#{vmdb_obj.href_slug}"
        end
      end
      result
    end

    def resolved_hosts
      @ae_object.substitute_value(@aem.options[:hosts], nil, true).tap do |value|
        raise ArgumentError, "Hosts field #{@aem.options[:hosts]} resolved to empty string" if value.blank?
      end
    end
  end
end
