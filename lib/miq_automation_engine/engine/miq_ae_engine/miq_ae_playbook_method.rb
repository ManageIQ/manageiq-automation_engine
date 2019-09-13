module MiqAeEngine
  class MiqAePlaybookMethod < MiqAeAnsibleMethodBase
    PLAYBOOK_CLASS = ManageIQ::Providers::EmbeddedAnsible::AutomationManager::Playbook

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
      rescue StandardError => err
        $miq_ae_logger.error("Playbook Method Ended with error #{err.message}")
        reset
        raise MiqAeException::AbortInstantiation, err.message
      end

      running_in_state_machine? ? check_task_status(task_id) : wait_for_method(task_id)
    end

    def build_options_hash
      super.tap do |config_info|
        config_info[:hosts] = resolved_hosts
      end
    end

    def resolved_hosts
      @ae_object.substitute_value(@aem.options[:hosts], nil, true).tap do |value|
        raise ArgumentError, "Hosts field #{@aem.options[:hosts]} resolved to empty string" if value.blank?
      end
    end
  end
end
