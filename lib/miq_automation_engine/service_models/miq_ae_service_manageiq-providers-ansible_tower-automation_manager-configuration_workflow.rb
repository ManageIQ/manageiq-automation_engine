module MiqAeMethodService
  class MiqAeServiceManageIQ_Providers_AnsibleTower_AutomationManager_ConfigurationWorkflow < MiqAeServiceManageIQ_Providers_Awx_AutomationManager_ConfigurationWorkflow
    expose :run

    def create_job(args)
      ar_method { wrap_results(ManageIQ::Providers::AnsibleTower::AutomationManager::WorkflowJob.create_job(@object, args)) }
    end
  end
end
