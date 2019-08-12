module MiqAeMethodService
  class MiqAeServiceManageIQ_Providers_Vmware_InfraManager_Vm < MiqAeServiceManageIQ_Providers_InfraManager_Vm
    def set_number_of_cpus(count, options = {})
      sync_or_async_ems_operation(options[:sync], "set_number_of_cpus", [count])
    end

    def set_memory(size_mb, options = {})
      sync_or_async_ems_operation(options[:sync], "set_memory", [size_mb])
    end

    def add_disk(disk_name, disk_size_mb, options = {})
      sync_or_async_ems_operation(options[:sync], "add_disk", [disk_name, disk_size_mb, options])
    end

    def remove_disk(disk_name, options = {})
      sync_or_async_ems_operation(options[:sync], "remove_disk", [disk_name, options])
    end

    def move_into_folder(folder, options = {})
      raise ArgumentError, "must be kind of MiqAeServiceEmsFolder" unless folder.kind_of?(MiqAeMethodService::MiqAeServiceEmsFolder)

      sync_or_async_ems_operation(options[:sync], "move_into_folder", [folder.id])
    end
  end
end
