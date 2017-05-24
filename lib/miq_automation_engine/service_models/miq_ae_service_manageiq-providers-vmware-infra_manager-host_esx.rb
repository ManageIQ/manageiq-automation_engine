module MiqAeMethodService
  class MiqAeServiceManageIQ_Providers_Vmware_InfraManager_HostEsx < MiqAeServiceManageIQ_Providers_Vmware_InfraManager_Host
    include MiqAeServiceEmsOperationsMixin
    require_relative "mixins/miq_ae_service_retirement_mixin"
    def shutdown(force = false)
      sync_or_async_ems_operation(false, "vim_shutdown", [force]) if @object.is_vmware?
      true
    end

    def reboot(force = false)
      sync_or_async_ems_operation(false, "vim_reboot", [force]) if @object.is_vmware?
      true
    end

    def enter_maintenance_mode(timeout = 0, evacuate = false)
      sync_or_async_ems_operation(false, "vim_enter_maintenance_mode", [timeout, evacuate]) if @object.is_vmware?
      true
    end

    def exit_maintenance_mode(timeout = 0)
      sync_or_async_ems_operation(false, "vim_exit_maintenance_mode", [timeout]) if @object.is_vmware?
      true
    end

    def in_maintenance_mode?
      object_send(:vim_in_maintenance_mode?) if @object.is_vmware?
    end

    def power_down_to_standby(timeout = 0, evacuate = false)
      sync_or_async_ems_operation(false, "vim_power_down_to_standby", [timeout, evacuate]) if @object.is_vmware?
      true
    end

    def power_up_from_standby(timeout = 0)
      sync_or_async_ems_operation(false, "vim_power_up_from_standby", [timeout]) if @object.is_vmware?
      true
    end

    def enable_vmotion(device = nil)
      sync_or_async_ems_operation(false, "vim_enable_vmotion", [device]) if @object.is_vmware?
      true
    end

    def disable_vmotion(device = nil)
      sync_or_async_ems_operation(false, "vim_disable_vmotion", [device]) if @object.is_vmware?
      true
    end

    def vmotion_enabled?(device = nil)
      object_send(:vim_vmotion_enabled?, device) if @object.is_vmware?
    end
  end
end
