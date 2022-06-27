module MiqAeMethodService
  class MiqAeServiceManageIQ_Providers_Awx_AutomationManager_WorkflowJob < MiqAeServiceManageIQ_Providers_ExternalAutomationManager_OrchestrationStack
    expose :refresh_ems

    def self.create_job(template, args = {})
      template_object = ConfigurationScript.find_by(:id => template.id)
      klass = ManageIQ::Providers::Awx::AutomationManager::WorkflowJob
      wrap_results(klass.create_job(template_object, args))
    end
  end
end
