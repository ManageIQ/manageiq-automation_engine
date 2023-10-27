module MiqAeMethodService
  class MiqAeServiceVmOrTemplate < MiqAeServiceModelBase
    require_relative "mixins/miq_ae_service_ems_operations_mixin"
    include MiqAeServiceEmsOperationsMixin
    require_relative "mixins/miq_ae_service_retirement_mixin"
    include MiqAeServiceRetirementMixin
    require_relative "mixins/miq_ae_service_inflector_mixin"
    include MiqAeServiceInflectorMixin
    require_relative "mixins/miq_ae_service_custom_attribute_mixin"
    include MiqAeServiceCustomAttributeMixin
    require_relative "mixins/miq_ae_service_remove_from_vmdb_mixin"
    include MiqAeServiceRemoveFromVmdb

    expose :ems_folder,            :association => true, :method => :parent_folder
    expose :ems_blue_folder,       :association => true, :method => :parent_blue_folder
    expose :resource_pool,         :association => true, :method => :parent_resource_pool
    expose :datacenter,            :association => true, :method => :parent_datacenter
    expose :registered?
    expose :to_s
    expose :event_threshold?
    expose :event_log_threshold?
    expose :performances_maintains_value_for_duration?
    expose :reconfigured_hardware_value?
    expose :changed_vm_value?
    expose :refresh, :method => :refresh_ems
    expose :evacuate
    expose :memory_for_request
    expose :number_of_cpus_for_request

    METHODS_WITH_NO_ARGS = %w[start stop suspend unregister collect_running_processes shutdown_guest standby_guest reboot_guest].freeze
    METHODS_WITH_NO_ARGS.each do |m|
      define_method(m) do
        sync_or_async_ems_operation(false, m)
        true
      end
    end

    def migrate(host, pool = nil, priority = "defaultPriority", state = nil)
      raise "Host Class must be MiqAeServiceHost, but is <#{host.class.name}>" unless host.kind_of?(MiqAeServiceHost)
      raise "Pool Class must be MiqAeServiceResourcePool, but is <#{pool.class.name}>" unless pool.nil? || pool.kind_of?(MiqAeServiceResourcePool)

      args = []
      args << host['id']
      args << (pool.nil? ? nil : pool['id'])
      args << priority
      args << state

      sync_or_async_ems_operation(false, "migrate_via_ids", args)
      true
    end

    def owner
      evm_owner = object_send(:evm_owner)
      wrap_results(evm_owner)
    end
    association :owner

    # Used to return string object instead of VimString to automate methods which end up with a DrbUnknow object.
    def ems_ref_string
      object_send(:ems_ref)
    end

    def scan(scan_categories = nil)
      options = scan_categories.nil? ? {} : {:categories => scan_categories}
      job = object_send(:scan, "system", options)
      wrap_results(job)
    end

    def unlink_storage
      _log.info("Unlinking storage on #{@object.class.name} id:<#{@object.id}>, name:<#{@object.name}>")
      object_send(:update, :storage_id => nil)
      true
    end

    def ems_custom_keys
      ar_method do
        @object.ems_custom_attributes.collect(&:name)
      end
    end

    def ems_custom_get(key)
      ar_method do
        c1 = @object.ems_custom_attributes.find_by(:name => key.to_s)
        c1.try(:value)
      end
    end

    def ems_custom_set(attribute, value)
      _log.info("Setting EMS Custom Key on #{@object.class.name} id:<#{@object.id}>, name:<#{@object.name}> with key=#{attribute.inspect} to #{value.inspect}")
      sync_or_async_ems_operation(false, "set_custom_field", [attribute, value])
      true
    end

    def owner=(owner)
      raise ArgumentError, "owner must be nil or a MiqAeServiceUser" unless owner.nil? || owner.kind_of?(MiqAeMethodService::MiqAeServiceUser)

      ar_method do
        @object.evm_owner = owner && owner.instance_variable_get("@object")
        _log.info("Setting EVM Owning User on #{@object.class.name} id:<#{@object.id}>, name:<#{@object.name}> to #{@object.evm_owner.inspect}")
        @object.save
      end
    end

    def group=(group)
      raise ArgumentError, "group must be nil or a MiqAeServiceMiqGroup" unless group.nil? || group.kind_of?(MiqAeMethodService::MiqAeServiceMiqGroup)

      ar_method do
        @object.miq_group = group && group.instance_variable_get("@object")
        _log.info("Setting EVM Owning Group on #{@object.class.name} id:<#{@object.id}>, name:<#{@object.name}> to #{@object.miq_group.inspect}")
        @object.save
      end
    end

    def remove_from_disk(sync = true)
      sync_or_async_ems_operation(sync, "vm_destroy")
    end

    def show_url
      URI.join(MiqRegion.my_region.remote_ui_url, "vm/show/#{@object.id}").to_s
    end
  end
end
