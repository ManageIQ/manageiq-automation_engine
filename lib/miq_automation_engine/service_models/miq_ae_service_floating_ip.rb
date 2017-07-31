module MiqAeMethodService
  class MiqAeServiceFloatingIp < MiqAeServiceModelBase
    expose :ext_management_system, :association => true
    expose :vm,                    :association => true
    expose :cloud_tenant,          :association => true
    expose :network_port,          :association => true
    expose :name
    expose :update_floating_ip
    expose :delete_floating_ip
  end
end
