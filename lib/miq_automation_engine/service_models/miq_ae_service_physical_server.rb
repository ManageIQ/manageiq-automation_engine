module MiqAeMethodService
  class MiqAeServicePhysicalServer < MiqAeServiceModelBase
    expose :turn_on_loc_led
    expose :turn_off_loc_led
    expose :power_on
    expose :power_off

    def self.create_server_profile_and_deploy_task(template_id, server_id, profile_name)
      profile_template = PhysicalServerProfileTemplate.find(template_id)
      profile_template.deploy_server_from_template_queue(server_id, profile_name)
    end
  end
end
