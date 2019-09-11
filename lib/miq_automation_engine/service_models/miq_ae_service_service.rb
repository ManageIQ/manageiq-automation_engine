module MiqAeMethodService
  class MiqAeServiceService < MiqAeServiceModelBase
    require_relative "mixins/miq_ae_service_retirement_mixin"
    include MiqAeServiceRetirementMixin
    require_relative "mixins/miq_ae_service_custom_attribute_mixin"
    include MiqAeServiceCustomAttributeMixin
    require_relative "mixins/miq_ae_service_remove_from_vmdb_mixin"
    include MiqAeServiceRemoveFromVmdb
    require_relative "mixins/miq_ae_external_url_mixin"
    include MiqAeExternalUrlMixin

    expose :retire_service_resources
    expose :automate_retirement_entrypoint
    expose :start
    expose :stop
    expose :suspend
    expose :shutdown_guest
    expose :direct_vms,                :association => true
    expose :indirect_vms,              :association => true
    expose :root_service,              :association => true
    expose :indirect_service_children, :association => true

    CREATE_ATTRIBUTES = [:name, :description, :service_template].freeze

    def self.create(options = {})
      attributes = options.symbolize_keys.slice(*CREATE_ATTRIBUTES)
      if attributes[:service_template]
        raise ArgumentError, "service_template must be a MiqAeServiceServiceTemplate" unless
          attributes[:service_template].kind_of?(MiqAeMethodService::MiqAeServiceServiceTemplate)
        attributes[:service_template] = ServiceTemplate.find(attributes[:service_template].id)
      end
      ar_method { MiqAeServiceModelBase.wrap_results(Service.create!(attributes)) }
    end

    def dialog_options
      @object.options[:dialog] || {}
    end

    def get_dialog_option(key)
      dialog_options[key]
    end

    def set_dialog_option(key, value)
      ar_method do
        @object.options[:dialog] ||= {}
        @object.options[:dialog][key] = value
        @object.update_attribute(:options, @object.options)
      end
    end

    def service_vars_options
      @object.options[:service_vars] ||= HashWithIndifferentAccess.new
    end

    def get_service_vars_option(key)
      service_vars_options[key]
    end

    def set_service_vars_option(key, value)
      ar_method do
        service_vars_options[key] = value
        @object.update(:options => @object.options)
      end
    end

    def delete_service_vars_option(key)
      return unless service_vars_options&.key?(key)

      ar_method do
        service_vars_options.delete(key).tap do
          @object.update(:options => @object.options)
        end
      end
    end

    def name=(new_name)
      ar_method do
        @object.update!(:name => new_name)
      end
    end

    def description=(new_description)
      ar_method { @object.update_attribute(:description, new_description) }
    end

    def display=(display)
      ar_method do
        @object.display = display
        @object.save
      end
    end

    def parent_service=(service)
      ar_method do
        if service
          raise ArgumentError, "service must be a MiqAeServiceService" unless service.kind_of?(
            MiqAeMethodService::MiqAeServiceService)
          @object.add_to_service(Service.find(service.id))
        elsif @object.parent.present?
          @object.remove_from_service(@object.parent)
        end
        @object.save
      end
    end

    def owner=(owner)
      if owner.nil? || owner.kind_of?(MiqAeMethodService::MiqAeServiceUser)
        if owner.nil?
          @object.evm_owner = nil
        else
          @object.evm_owner = User.find_by(:id => owner.id)
        end
        @object.save
      end
    end

    def group=(group)
      if group.nil? || group.kind_of?(MiqAeMethodService::MiqAeServiceMiqGroup)
        if group.nil?
          @object.miq_group = nil
        else
          @object.miq_group = MiqGroup.find_by(:id => group.id)
        end
        @object.save
      end
    end

    def show_url
      URI.join(MiqRegion.my_region.remote_ui_url, "service/show/#{@object.id}").to_s
    end
  end
end
