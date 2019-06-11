module MiqAeMethodService
  class MiqAeServiceMiqGroup < MiqAeServiceModelBase
    require_relative "mixins/miq_ae_service_custom_attribute_mixin"
    include MiqAeServiceCustomAttributeMixin
    require_relative "mixins/miq_ae_external_url_mixin"
    include MiqAeExternalUrlMixin

    expose :filters, :method => :get_filters
  end
end
