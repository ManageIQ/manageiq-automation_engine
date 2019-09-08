module MiqAeMethodService
  class MiqAeServiceStorage < MiqAeServiceModelBase
    expose :ext_management_systems, :association => true
    expose :unregistered_vms,       :association => true
    expose :to_s
    expose :scan, :override_return => true

    def show_url
      URI.join(MiqRegion.my_region.remote_ui_url, "storage/show/#{@object.id}").to_s
    end
  end
end
