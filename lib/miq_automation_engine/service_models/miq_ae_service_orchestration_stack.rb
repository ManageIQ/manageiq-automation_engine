module MiqAeMethodService
  class MiqAeServiceOrchestrationStack < MiqAeServiceModelBase
    require_relative "mixins/miq_ae_service_retirement_mixin"
    include MiqAeServiceRetirementMixin
    require_relative "mixins/miq_ae_service_remove_from_vmdb_mixin"
    include MiqAeServiceRemoveFromVmdb

    expose :parameters,             :association => true
    expose :resources,              :association => true
    expose :outputs,                :association => true
    expose :ext_management_system,  :association => true
    expose :ems_ref
    expose :raw_delete_stack
    expose :raw_update_stack
    expose :raw_exists?
    expose :refresh, :method => :refresh_ems

    def add_to_service(service)
      error_msg = "service must be a MiqAeServiceService"
      raise ArgumentError, error_msg unless service.kind_of?(MiqAeMethodService::MiqAeServiceService)
      ar_method { wrap_results(Service.find_by(:id => service.id).add_resource!(@object)) }
    end

    def normalized_live_status
      @object.raw_status.try(:normalized_status)
    rescue MiqException::MiqOrchestrationStackNotExistError => err
      ['not_exist', err.message]
    end

    def self.refresh(manager_id, manager_ref)
      OrchestrationStack.refresh_ems(manager_id, manager_ref)
    end
  end
end
