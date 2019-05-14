module MiqAeMethodService
  class MiqAeServiceHardware < MiqAeServiceModelBase
    expose :ipaddresses

    def mac_addresses
      object_send(:nics).collect(&:address)
    end
  end
end
