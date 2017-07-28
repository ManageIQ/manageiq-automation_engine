module MiqAeMethodService
  class MiqAeServiceSecurityGroup < MiqAeServiceModelBase
    expose :ext_management_system, :association => true
    expose :cloud_network,         :association => true
    expose :cloud_tenant,          :association => true
    expose :firewall_rules,        :association => true
    expose :vms,                   :association => true
    expose :update_security_group
    expose :delete_security_group
  end
end
