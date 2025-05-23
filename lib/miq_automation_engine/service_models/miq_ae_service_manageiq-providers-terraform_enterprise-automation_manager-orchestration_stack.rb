module MiqAeMethodService
  class MiqAeServiceManageIQ_Providers_TerraformEnterprise_AutomationManager_OrchestrationStack < MiqAeServiceManageIQ_Providers_ExternalAutomationManager_OrchestrationStack
    expose :refresh_ems
    expose :raw_stdout

    def self.create_job(workspace, args = {})
      workspace_object = ConfigurationScript.find_by(:id => workspace.id)
      klass = ManageIQ::Providers::TerraformEnterprise::AutomationManager::OrchestrationStack
      wrap_results(klass.create_stack(workspace_object, args))
    end
  end
end
