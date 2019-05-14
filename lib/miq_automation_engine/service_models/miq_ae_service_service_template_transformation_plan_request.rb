module MiqAeMethodService
  class MiqAeServiceServiceTemplateTransformationPlanRequest < MiqAeServiceServiceTemplateProvisionRequest
    expose :source_vms, :association => true
    expose :validate_conversion_hosts
    expose :validate_vm, :association => true
    expose :approve_vm, :association => true
  end
end
