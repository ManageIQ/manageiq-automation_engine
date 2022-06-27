module MiqAeMethodService
  class MiqAeServiceManageIQ_Providers_Awx_AutomationManager_ConfigurationScript < MiqAeServiceManageIQ_Providers_ExternalAutomationManager_ConfigurationScript
    expose :run

    def create_job(args)
      ar_method { wrap_results(ManageIQ::Providers::Awx::AutomationManager::Job.create_job(@object, args)) }
    end
  end
end
