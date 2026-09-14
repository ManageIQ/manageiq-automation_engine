module MiqAeMethodService
  class MiqAeServiceEmsCluster < MiqAeServiceModelBase
    require_relative "mixins/miq_ae_service_ems_operations_mixin"
    include MiqAeServiceEmsOperationsMixin
    expose :default_resource_pool, :association => true
    expose :all_resource_pools,    :association => true
    expose :all_vms,               :association => true
    expose :parent_folder,         :association => true
    expose :ems_events,            :association => true
    def register_host(host)
      sync_or_async_ems_operation(false, "register_host", [host.id])
      true
    end

    def show_url
      remote_ui_url = MiqRegion.my_region.remote_ui_url
      return nil if remote_ui_url.nil?

      URI.join(remote_ui_url, "ems_cluster/show/#{@object.id}").to_s
    end
  end
end
