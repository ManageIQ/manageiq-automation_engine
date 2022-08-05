module MiqAeMethodService
  class MiqAeServiceManageIQ_Providers_Ovirt_InfraManager < MiqAeServiceEmsInfra
    expose :supports_vm_import?
    expose :submit_import_vm
    expose :submit_configure_imported_vm_networks
  end
end
