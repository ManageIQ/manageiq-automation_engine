module MiqAeEngine
  class MiqAeBuiltinMethod
    # All Class Methods beginning with miq_ are callable from the engine
    ATTRIBUTE_LIST = %w[
      vm
      orchestration_stack
      miq_request
      miq_provision
      vm_migrate_task
      vm_retire_task
      service_retire_task
      orchestration_stack_retire_task
      physical_server_provision_task
      platform_category
    ].freeze
    CLOUD          = 'cloud'.freeze
    INFRASTRUCTURE = 'infrastructure'.freeze
    PHYSICAL_INFRA = 'physicalinfrastructure'.freeze
    SERVICE        = 'service'.freeze
    UNKNOWN        = 'unknown'.freeze

    def self.miq_log_object(obj, _inputs)
      $miq_ae_logger.info("===========================================")
      $miq_ae_logger.info("Dumping Object")

      $miq_ae_logger.info("Listing Object Attributes:")
      obj.attributes.sort.each { |k, v| $miq_ae_logger.info("\t#{k}: #{v}") }
      $miq_ae_logger.info("===========================================")
    end

    def self.miq_log_workspace(obj, _inputs)
      $miq_ae_logger.info("===========================================")
      $miq_ae_logger.info("Dumping Workspace")
      $miq_ae_logger.info(obj.workspace.to_expanded_xml)
      $miq_ae_logger.info("===========================================")
    end

    def self.miq_send_email(_obj, inputs)
      MiqAeMethodService::MiqAeServiceMethods.send_email(inputs["to"], inputs["from"], inputs["subject"], inputs["body"], :cc => inputs["cc"], :bcc => inputs["bcc"], :content_type => inputs["content_type"])
    end

    def self.miq_snmp_trap_v1(_obj, inputs)
      MiqAeMethodService::MiqAeServiceMethods.snmp_trap_v1(inputs)
    end

    def self.miq_snmp_trap_v2(_obj, inputs)
      MiqAeMethodService::MiqAeServiceMethods.snmp_trap_v2(inputs)
    end

    def self.powershell(_obj, inputs)
      MiqAeMethodService::MiqAeServiceMethods.powershell(inputs['script'], inputs['returns'])
    end

    def self.miq_parse_provider_category(obj, _inputs)
      provider_category = nil
      ATTRIBUTE_LIST.detect { |attr| provider_category = category_for_key(obj, attr) }
      $miq_ae_logger.info("Setting provider_category to: #{provider_category}", :resource_id => obj.workspace.find_miq_request_id)
      obj.workspace.root["ae_provider_category"] = provider_category || UNKNOWN
    end

    def self.miq_parse_automation_request(obj, _inputs)
      obj['target_component'], obj['target_class'], obj['target_instance'] =
        case obj['request']
        when 'vm_provision'               then %w[VM            Lifecycle Provisioning]
        when 'vm_retired'                 then %w[VM            Lifecycle Retirement]
        when 'vm_retire'                  then %w[VM            Lifecycle Retirement]
        when 'vm_migrate'                 then %w[VM            Lifecycle Migrate]
        when 'service_retire'             then %w[Service       Lifecycle Retirement]
        when 'orchestration_stack_retire' then %w[Orchestration Lifecycle Retirement]
        when 'configured_system_provision'
          obj.workspace.root['ae_provider_category'] = 'infrastructure'
          %w[Configured_System Lifecycle Provisioning]
        when 'physical_server_provision' then %w[PhysicalServer Lifecycle Provisioning]
        end

      miq_request_id = obj.workspace.find_miq_request_id
      $miq_ae_logger.info("Request:<#{obj['request']}> Target Component:<#{obj['target_component']}> ", :resource_id => miq_request_id)
      $miq_ae_logger.info("Target Class:<#{obj['target_class']}> Target Instance:<#{obj['target_instance']}>", :resource_id => miq_request_id)
    end

    def self.miq_host_and_storage_least_utilized(obj, _inputs)
      prov = obj.workspace.get_obj_from_path("/")['miq_provision']
      raise MiqAeException::MethodParmMissing, "Provision not specified" if prov.nil?

      vm = prov.vm_template
      ems = vm.ext_management_system
      raise "EMS not found for VM [#{vm.name}" if ems.nil?

      min_running_vms = nil
      result = {}
      ems.hosts.each do |h|
        next unless h.power_state == "on"

        nvms = h.vms.collect { |v| v if v.power_state == "on" }.compact.length
        next unless min_running_vms.nil? || nvms < min_running_vms

        storages = h.writable_storages.find_all { |s| s.free_space > vm.provisioned_storage } # Filter out storages that do not have enough free space for the Vm
        s = storages.max_by(&:free_space)
        next if s.nil?

        result["host"]    = h
        result["storage"] = s
        min_running_vms   = nvms
      end

      ["host", "storage"].each { |k| obj[k] = result[k] } unless result.empty?
    end

    def self.miq_refresh(obj, _inputs)
      event_object_from_workspace(obj).manager_refresh(:sync => false)
    end

    def self.miq_refresh_sync(obj, _inputs)
      event_object_from_workspace(obj).manager_refresh(:sync => true)
    end

    def self.miq_event_action_refresh(obj, inputs)
      event_object_from_workspace(obj).refresh(inputs['target'], false)
    end

    def self.miq_event_action_refresh_sync(obj, inputs)
      event_object_from_workspace(obj).refresh(inputs['target'], true)
    end

    def self.miq_event_action_policy(obj, inputs)
      event_object_from_workspace(obj).policy(inputs['target'], inputs['policy_event'], inputs['param'])
    end

    def self.miq_event_action_scan(obj, inputs)
      event_object_from_workspace(obj).scan(inputs['target'])
    end

    def self.miq_src_vm_as_template(obj, inputs)
      event_object_from_workspace(obj).src_vm_as_template(inputs['flag'])
    end

    def self.miq_change_event_target_state(obj, inputs)
      event_object_from_workspace(obj).change_event_target_state(inputs['target'], inputs['param'])
    end

    def self.miq_src_vm_destroy_all_snapshots(obj, _inputs)
      event_object_from_workspace(obj).src_vm_destroy_all_snapshots
    end

    def self.miq_src_vm_disconnect_storage(_obj, _inputs)
      # Logic for storage disconnect has been moved to VmOrTemplate#disconnect_inv
      # This method is kept for compatibility and will be removed in a future version
    end

    def self.miq_event_enforce_policy(obj, _inputs)
      event_object_from_workspace(obj).process_evm_event
    end

    def self.miq_check_policy_prevent(obj, _inputs)
      event = event_object_from_workspace(obj)
      if event.full_data && event.full_data[:policy][:prevented]
        msg = "Event #{event.event_type} for #{event.target} was terminated: #{event.message}"
        raise MiqAeException::StopInstantiation, msg
      end
    end

    def self.event_object_from_workspace(obj)
      event = obj.workspace.get_obj_from_path("/")['event_stream']
      raise MiqAeException::MethodParmMissing, "Event not specified" if event.nil?

      event
    end
    private_class_method :event_object_from_workspace

    def self.vm_detect_category(prov_obj_source)
      return nil unless prov_obj_source.respond_to?(:cloud)

      prov_obj_source.cloud ? CLOUD : INFRASTRUCTURE
    end
    private_class_method :vm_detect_category

    def self.detect_platform_category(platform_category)
      platform_category == 'infra' ? INFRASTRUCTURE : platform_category
    end
    private_class_method :detect_platform_category

    def self.detect_category(obj_name, prov_obj)
      case obj_name
      when "orchestration_stack", "orchestration_stack_retire_task"
        CLOUD
      when "miq_request"
        case prov_obj
        when nil
          nil
        when PhysicalServerProvisionRequest
          PHYSICAL_INFRA
        else
          vm_detect_category(prov_obj.source)
        end
      when "miq_provision", "vm_migrate_task", "vm_retire_task"
        vm_detect_category(prov_obj.source) if prov_obj
      when "service_retire_task"
        ""
      when "vm"
        vm_detect_category(prov_obj) if prov_obj
      when "physical_server_provision_task"
        PHYSICAL_INFRA
      else
        UNKNOWN
      end
    end
    private_class_method :detect_category

    def self.category_for_key(obj, key)
      if key == "platform_category"
        key_object = obj.workspace.root
        detect_platform_category(key_object[key]) if key_object[key]
      else
        key_object = obj.workspace.root[key]
        detect_category(key, key_object) if key_object
      end
    end
    private_class_method :category_for_key

    def self.detect_vendor(src_obj, attr)
      return unless src_obj

      case attr
      when "orchestration_stack"
        src_obj.ext_management_system.try(:provider_name)
      when "miq_request", "miq_provision", "vm_migrate_task"
        src_obj.source.try(:provider_name)
      when "vm"
        src_obj.try(:provider_name)
      end
    end

    def self.emsevent_provider_name(event_stream)
      return nil if event_stream.ext_management_system.nil?

      event_stream.ext_management_system.try(:provider_name)
    end
    private_class_method :emsevent_provider_name

    def self.emsevent_manager_type(event_stream)
      return nil if event_stream.ext_management_system.nil?

      manager_type = event_stream.ext_management_system.try(:manager_type).downcase
      manager_type == "infra" ? INFRASTRUCTURE : manager_type
    end
    private_class_method :emsevent_manager_type

    def self.emsevent?(event_stream)
      event_stream.object_class.name.casecmp("emsevent").zero?
    end
    private_class_method :emsevent?

    def self.miq_parse_event_stream(obj, _attr)
      event_stream = obj.workspace.root['event_stream']
      raise "Event Stream object not found" if event_stream.nil?

      if emsevent?(event_stream)
        provider_name = emsevent_provider_name(event_stream)
        raise "EMS event - Invalid provider" if provider_name.blank?

        manager_type = emsevent_manager_type(event_stream)
        raise "EMS event - Invalid manager type" if manager_type.blank?

        obj.workspace.root['event_path'] = "/#{provider_name}/EMSEvent/#{manager_type}/Event"
      else
        obj.workspace.root['event_path'] = "/System/Event/#{event_stream.event_namespace}/#{event_stream.source}"
      end
    end
  end
end
