module MiqAeMethodService
  class MiqAeServiceCloudVolume < MiqAeServiceModelBase
    require_relative "mixins/miq_ae_service_ems_operations_mixin"
    include MiqAeServiceEmsOperationsMixin

    expose :create_volume_snapshot, :override_return => nil
    expose :attach_volume,          :override_return => nil
    expose :detach_volume,          :override_return => nil
  end
end
