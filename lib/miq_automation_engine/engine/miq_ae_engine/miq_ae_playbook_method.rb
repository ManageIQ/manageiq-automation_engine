module MiqAeEngine
  class MiqAePlaybookMethod
    PLAYBOOK_CLASS = ManageIQ::Providers::EmbeddedAnsible::AutomationManager::Job
    METHOD_KEY_SUFFIX = "_ansible_method_task_id".freeze

    def initialize(aem, obj, inputs)
      @workspace = obj.workspace
      @inputs    = inputs
      @aem       = aem
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
      $miq_ae_logger.info("Playbook Method passing options to runner: #{playbook_options}")
      begin
        task_id = PLAYBOOK_CLASS.run(playbook_options)
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
      @workspace.root['ae_retry_interval'] = 1.minute
      @workspace.persist_state_hash['automate_workspace_guid'] = @aw.guid
      @workspace.persist_state_hash[method_key] = task_id
    end

    def manageiq_env
      {
        'api_token'      => Api::UserTokenService.new.generate_token(@workspace.ae_user.userid, 'api'),
        'api_url'        => MiqRegion.my_region.remote_ws_url,
        'workspace_guid' => @aw.guid,
        'miq_group'      => @workspace.ae_user.current_group.description
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
      config_info = YAML.load(@aem.data)
      config_info[:extra_vars] = MiqAeReference.encode(@inputs)
      config_info[:extra_vars][:manageiq] = manageiq_env
      { :name => @aem.name, :config_info => config_info }
    end
  end
end
