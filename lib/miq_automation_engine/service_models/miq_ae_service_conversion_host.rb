module MiqAeMethodService
  class MiqAeServiceConversionHost < MiqAeServiceModelBase
    expose :active_tasks
    expose :eligible?
    expose :check_conversion_host_role
    expose :enable_conversion_host_role
    expose :disable_conversion_host_role
    expose :ext_management_system
  end
end
