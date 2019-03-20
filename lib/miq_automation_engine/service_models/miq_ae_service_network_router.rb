module MiqAeMethodService
  class MiqAeServiceNetworkRouter < MiqAeServiceModelBase
    expose :public_network,        :association => true
    expose :private_networks,      :association => true
  end
end
