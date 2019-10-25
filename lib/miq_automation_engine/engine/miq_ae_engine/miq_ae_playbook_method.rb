module MiqAeEngine
  class MiqAePlaybookMethod < MiqAeAnsibleMethodBase
    include AnsiblePlaybookMixin

    PLAYBOOK_CLASS = ManageIQ::Providers::EmbeddedAnsible::AutomationManager::Playbook
    STACK_CLASS = ManageIQ::Providers::EmbeddedAnsible::AutomationManager::Job

    private

    def execute
      @aw = AutomateWorkspace.create(:input  => serialize_workspace,
                                     :user   => @workspace.ae_user,
                                     :tenant => @workspace.ae_user.current_tenant)

      launch_options = build_launch_options
      $miq_ae_logger.info("Playbook Method passing options:")
      $miq_ae_logger.log_hashes(launch_options)

      begin
        @stack_job = STACK_CLASS.create_job(playbook, launch_options)
        $miq_ae_logger.info("Ansible job with ref #{@stack_job.ems_ref} was created.")
        task_id = @stack_job.miq_task.id
      rescue StandardError => err
        $miq_ae_logger.error("Playbook Method Ended with error #{err.message}")
        reset
        raise MiqAeException::AbortInstantiation, err.message
      end

      running_in_state_machine? ? check_task_status(task_id) : wait_for_method(task_id)
    end

    def process_result(task)
      job = stack_job(task)
      job.refresh_ems
      log_stdout(job.reload)
      super
    end

    def build_options_hash
      super.tap do |config_info|
        config_info[:hosts] = resolved_hosts
      end
    end

    def build_launch_options
      @build_launch_options ||= build_options_hash.slice(*CONFIG_OPTIONS_WHITELIST).tap do |options|
        options[:hosts] = hosts_array(build_options_hash[:hosts])
        translate_credentials!(options)
      end
    end

    def playbook
      @playbook ||= PLAYBOOK_CLASS.find_by(:id => @aem.options[:playbook_id])
    end

    def stack_job(task)
      @stack_job ||= STACK_CLASS.find_by(:miq_task => task)
    end

    def resolved_hosts
      @ae_object.substitute_value(@aem.options[:hosts], nil, true).tap do |value|
        raise ArgumentError, "Hosts field #{@aem.options[:hosts]} resolved to empty string" if value.blank?
      end
    end

    def log_stdout(job)
      playbook_log_stdout(@aem.options[:log_output], job)
    end
  end
end
