module MiqAeMethodService
  class MiqAeServiceManageIQ_Providers_AnsibleTower_AutomationManager_Job < MiqAeServiceManageIQ_Providers_Awx_AutomationManager_Job
    expose :refresh_ems
    expose :raw_stdout

    def self.create_job(template, args = {})
      template_object = ConfigurationScript.find_by(:id => template.id)
      klass = ManageIQ::Providers::AnsibleTower::AutomationManager::Job
      wrap_results(klass.create_job(template_object, args))
    end
  end
end
