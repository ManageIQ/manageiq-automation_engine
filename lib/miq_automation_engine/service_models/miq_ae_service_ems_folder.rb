module MiqAeMethodService
  class MiqAeServiceEmsFolder < MiqAeServiceModelBase
    require_relative "mixins/miq_ae_service_ems_operations_mixin"
    include MiqAeServiceEmsOperationsMixin

    expose :hosts, :association => true
    expose :vms,   :association => true

    def register_host(host)
      sync_or_async_ems_operation(false, "register_host", [host.id])
      true
    end

    # default options:
    #  :exclude_root_folder => false
    #  :exclude_non_display_folders => false
    def folder_path(*options)
      object_send(:folder_path, *options)
    end
  end
end
