module MiqAeEngine
  class MiqAeAnsibleTemplateMethod < MiqAeAnsibleMethodBase
    TEMPLATE_CLASS = ManageIQ::Providers::AutomationManager::ConfigurationScript

    private

    def execute
      @aw = AutomateWorkspace.create(:input  => serialize_workspace,
                                     :user   => @workspace.ae_user,
                                     :tenant => @workspace.ae_user.current_tenant)
      template_options = build_options_hash
      $miq_ae_logger.info("Ansible Template Method passing options: #{template_options.inspect}")
      begin
        template = TEMPLATE_CLASS.find(template_options[:ansible_template_id])
        $miq_ae_logger.info("Calling template.run_with_miq_job for template: #{template.inspect}")
        task_id = template.run_with_miq_job(template_options)
      rescue StandardError => err
        $miq_ae_logger.error("Ansible Template Method Ended with error #{err.message}")
        reset
        raise MiqAeException::AbortInstantiation, err.message
      end

      running_in_state_machine? ? check_task_status(task_id) : wait_for_method(task_id)
    end
  end
end
