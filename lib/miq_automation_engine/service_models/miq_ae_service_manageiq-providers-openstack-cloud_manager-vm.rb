module MiqAeMethodService
  class MiqAeServiceManageIQ_Providers_Openstack_CloudManager_Vm < MiqAeServiceVmCloud
    expose :resize,         :override_return => nil
    expose :resize_confirm, :override_return => nil
    expose :resize_revert,  :override_return => nil

    # @return [boolean] (not using supports)
    expose :validate_resize_confirm
    # @return [boolean] (not using supports)
    expose :validate_resize_revert

    expose :associate_floating_ip,    :override_return => nil
    expose :disassociate_floating_ip, :override_return => nil

    expose :associate_floating_ip_from_network
    expose :delete_floating_ips

    def attach_volume(volume_id, device = nil, options = {})
      sync_or_async_ems_operation(options[:sync], "attach_volume", [volume_id, device])
    end

    def detach_volume(volume_id, options = {})
      sync_or_async_ems_operation(options[:sync], "detach_volume", [volume_id])
    end

    # backwards compatible
    def supports_resize?
      object_send(:supports?, :resize)
    end

    # this implents the AvailabilityMixin interface
    # for backwards compatibility in customer scripts
    # prefer using supports?(:resize) method instead
    def validate_resize
      reason = object_send(:unsupported_reason, :resize)
      {:available => !reason, :message => reason}
    end
  end
end
