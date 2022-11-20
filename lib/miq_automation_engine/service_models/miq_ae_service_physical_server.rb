module MiqAeMethodService
  class MiqAeServicePhysicalServer < MiqAeServiceModelBase
    expose :turn_on_loc_led
    expose :turn_off_loc_led
    expose :power_on
    expose :power_off

    def self.create_server_profile_and_deploy_task(ems)
      ext_management_system = ExtManagementSystem.find(ems)
      PhysicalServerProfileTemplate.check
    end
  end
end
