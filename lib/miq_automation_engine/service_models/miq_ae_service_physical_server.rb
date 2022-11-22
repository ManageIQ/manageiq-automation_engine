module MiqAeMethodService
  class MiqAeServicePhysicalServer < MiqAeServiceModelBase
    expose :turn_on_loc_led
    expose :turn_off_loc_led
    expose :power_on
    expose :power_off

    def self.create_server_profile_and_deploy_task(ems_id, template_id, server_id, profile_name)
      ext_management_system = ExtManagementSystem.find(ems_id)
      profile_template = PhysicalServerProfileTemplate.find(template_id)
      task_id = profile_template.deploy_server_from_template_queue(ext_management_system, server_id, profile_name)
      MiqTask.wait_for_taskid(task_id)
    end
  end
end
