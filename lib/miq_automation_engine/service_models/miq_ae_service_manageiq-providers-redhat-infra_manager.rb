module MiqAeMethodService
  class MiqAeServiceManageIQ_Providers_Redhat_InfraManager < MiqAeServiceEmsInfra
    expose :validate_import_vm
    expose :submit_import_vm
    expose :submit_configure_imported_vm_networks
    expose :exists_on_provider?
  end
end
