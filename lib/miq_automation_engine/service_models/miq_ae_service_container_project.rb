module MiqAeMethodService
  class MiqAeServiceContainerProject < MiqAeServiceModelBase
    expose :ext_management_system,  :association => true
    expose :container_groups,       :association => true
    expose :create_resource
    expose :add_role_to_user
    expose :subjects_with_role
    expose :update_in_provider
    expose :delete_from_provider
  end
end
