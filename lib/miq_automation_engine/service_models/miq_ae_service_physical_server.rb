module MiqAeMethodService
  class MiqAeServicePhysicalServer < MiqAeServiceModelBase
    expose :ext_management_system, :association => true

    expose :turn_on_loc_led
    expose :turn_off_loc_led
    expose :power_on
    expose :power_off
  end
end
