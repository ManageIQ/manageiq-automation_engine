module MiqAeMethodService
  class MiqAeServiceManageIQ_Providers_CloudManager_Vm < MiqAeServiceVm
    expose :cloud_network,     :association => true
    expose :cloud_subnet,      :association => true
  end
end
