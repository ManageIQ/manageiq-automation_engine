module MiqAeMethodService
  class MiqAeServiceMiqProvision < MiqAeServiceMiqProvisionTask
    require_relative "mixins/miq_ae_service_miq_provision_mixin"
    include MiqAeServiceMiqProvisionMixin

    expose :target_type
    expose :source_type
    expose :update_vm_name
    expose :statemachine_task_status

    expose_eligible_resources :hosts
    expose_eligible_resources :storages
    expose_eligible_resources :folders
    expose_eligible_resources :clusters
    expose_eligible_resources :resource_pools
    expose_eligible_resources :pxe_servers
    expose_eligible_resources :pxe_images
    expose_eligible_resources :windows_images
    expose_eligible_resources :customization_templates
    expose_eligible_resources :iso_images

    def get_network_scope
      object_send(:get_network_scope)
    end

    def get_domain_name
      object_send(:get_domain)
    end

    def get_network_details
      object_send(:get_network_details)
    end

    def set_folder(folder_path)
      object_send(:set_folder, folder_path)
    end
  end
end
