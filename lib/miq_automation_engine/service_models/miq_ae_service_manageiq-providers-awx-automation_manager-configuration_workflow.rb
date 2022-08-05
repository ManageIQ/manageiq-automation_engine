module MiqAeMethodService
  class MiqAeServiceManageIQ_Providers_Awx_AutomationManager_ConfigurationWorkflow < MiqAeServiceManageIQ_Providers_ExternalAutomationManager_ConfigurationScript
    expose :run

    def create_job(args)
      ar_method { wrap_results(ManageIQ::Providers::Awx::AutomationManager::WorkflowJob.create_job(@object, args)) }
    end
  end
end
