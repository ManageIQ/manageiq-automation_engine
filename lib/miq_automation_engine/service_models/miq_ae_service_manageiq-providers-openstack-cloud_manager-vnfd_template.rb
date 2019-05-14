module MiqAeMethodService
  class MiqAeServiceManageIQ_Providers_Openstack_CloudManager_VnfdTemplate < MiqAeServiceOrchestrationTemplate
    CREATE_ATTRIBUTES = [:name, :description, :content, :draft, :orderable, :ems_id].freeze

    def self.create(options = {})
      attributes = options.symbolize_keys.slice(*CREATE_ATTRIBUTES)
      attributes[:remote_proxy] = true

      ar_method { MiqAeServiceManageIQ_Providers_Openstack_CloudManager_VnfdTemplate.wrap_results(ManageIQ::Providers::Openstack::CloudManager::VnfdTemplate.create!(attributes)) }
    end
  end
end
