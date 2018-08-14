module MiqAeMethodService
  class MiqAeServiceServiceTemplateTransformationPlanTask < MiqAeServiceServiceTemplateProvisionTask
    expose :update_transformation_progress
    expose :pre_ansible_playbook_service_template
    expose :post_ansible_playbook_service_template
    expose :mark_vm_migrated
    expose :canceling
    expose :canceled

    def transformation_destination(source_obj)
      ar_method do
        wrap_results(@object.transformation_destination(source_obj.object_class.find(source_obj.id)))
      end
    end
  end
end
