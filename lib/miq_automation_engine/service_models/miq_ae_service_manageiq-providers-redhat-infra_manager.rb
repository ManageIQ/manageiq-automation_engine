module MiqAeMethodService
  class MiqAeServiceManageIQ_Providers_Redhat_InfraManager < MiqAeServiceManageIQ_Providers_Ovirt_InfraManager
    expose :submit_import_vm
    expose :submit_configure_imported_vm_networks
  end
end
