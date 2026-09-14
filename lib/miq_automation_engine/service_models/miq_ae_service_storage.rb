module MiqAeMethodService
  class MiqAeServiceStorage < MiqAeServiceModelBase
    expose :ext_management_systems, :association => true
    expose :unregistered_vms,       :association => true
    expose :to_s
    expose :scan, :override_return => true

    def show_url
      remote_ui_url = MiqRegion.my_region.remote_ui_url
      return nil if remote_ui_url.nil?

      URI.join(remote_ui_url, "storage/show/#{@object.id}").to_s
    end
  end
end
