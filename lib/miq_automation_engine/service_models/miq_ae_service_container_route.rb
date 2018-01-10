module MiqAeMethodService
  class MiqAeServiceContainerRoute < MiqAeServiceModelBase
    require_relative 'mixins/miq_ae_service_container_resource_mixin'
    include MiqAeServiceContainerResourceMixin
    expose :ext_management_system,    :association => true
    expose :container_project,        :association => true
    expose :container_service,        :association => true
    expose :container_nodes,          :association => true
    expose :container_groups,         :association => true
    expose :labels,                   :association => true
    expose :is_tagged_with?
    expose :tags
  end
end
