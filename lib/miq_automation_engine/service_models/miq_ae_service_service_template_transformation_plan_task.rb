module MiqAeMethodService
  class MiqAeServiceServiceTemplateTransformationPlanTask < MiqAeServiceServiceTemplateProvisionTask
    expose :update_transformation_progress
    expose :pre_ansible_playbook_service_template
    expose :post_ansible_playbook_service_template
    expose :mark_vm_migrated
    expose :canceling
    expose :canceled
    expose :preflight_check
    expose :source_cluster
    expose :destination_cluster
    expose :source_ems
    expose :destination_ems
    expose :transformation_type
    expose :virtv2v_disks
    expose :network_mappings
    expose :destination_flavor
    expose :destination_security_group
    expose :conversion_host
    expose :conversion_options
    expose :run_conversion
    expose :get_conversion_state
    expose :kill_virtv2v

    def transformation_destination(source_obj)
      ar_method do
        wrap_results(@object.transformation_destination(source_obj.object_class.find(source_obj.id)))
      end
    end

    def conversion_host=(conversion_host)
      raise ArgumentError, "conversion_host must be nil or a MiqAeServiceConversionHost" unless conversion_host.nil? || conversion_host.kind_of?(MiqAeMethodService::MiqAeServiceConversionHost)

      ar_method do
        @object.conversion_host = conversion_host && conversion_host.instance_variable_get("@object")
        _log.info "Setting Conversion Host on #{@object.class.name} id:<#{@object.id}> to #{@object.conversion_host.inspect}"
        @object.save
      end 
    end 
  end
end
