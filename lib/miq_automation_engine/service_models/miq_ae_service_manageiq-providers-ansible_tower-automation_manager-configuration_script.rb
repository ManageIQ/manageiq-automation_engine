module MiqAeMethodService
  class MiqAeServiceManageIQ_Providers_AnsibleTower_AutomationManager_ConfigurationScript < MiqAeServiceManageIQ_Providers_Awx_AutomationManager_ConfigurationScript
    expose :run

    def create_job(args)
      ar_method { wrap_results(ManageIQ::Providers::AnsibleTower::AutomationManager::Job.create_job(@object, args)) }
    end
  end
end
