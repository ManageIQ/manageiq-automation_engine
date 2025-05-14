module MiqAeMethodService
  class MiqAeServiceServiceTerraformEnterprise < MiqAeServiceService
    expose :terraform_workspace
    expose :configuration_manager
    expose :launch_stack
    expose :stack
    expose :stack_options
    expose :stack_options=
  end
end
