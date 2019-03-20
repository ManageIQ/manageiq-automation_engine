module MiqAeMethodService
  class MiqAeServiceManageIQ_Providers_CloudManager < MiqAeServiceManageIQ_Providers_BaseManager
    expose :cloud_networks,         :association => true
    expose :public_networks,        :association => true
    expose :private_networks,       :association => true
    expose :floating_ips,           :association => true
    expose :security_groups,        :association => true

    def create_cloud_tenant(create_options, options = {})
      sync_or_async_ems_operation(options[:sync], "create_cloud_tenant", [create_options])
    end
  end
end
