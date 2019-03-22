module MiqAeMethodService
  class MiqAeServiceManageIQ_Providers_Redhat_InfraManager < MiqAeServiceManageIQ_Providers_InfraManager
    expose :supports_vm_import?
    expose :submit_import_vm
    expose :submit_configure_imported_vm_networks
  end
end
