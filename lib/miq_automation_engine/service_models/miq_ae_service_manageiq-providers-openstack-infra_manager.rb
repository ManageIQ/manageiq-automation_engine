module MiqAeMethodService
  class MiqAeServiceManageIQ_Providers_Openstack_InfraManager < MiqAeServiceManageIQ_Providers_InfraManager
    expose :orchestration_stacks, :association => true
    expose :direct_orchestration_stacks, :association => true
  end
end
