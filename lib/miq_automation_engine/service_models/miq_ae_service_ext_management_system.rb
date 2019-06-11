module MiqAeMethodService
  class MiqAeServiceExtManagementSystem < MiqAeServiceModelBase
    require_relative "mixins/miq_ae_service_inflector_mixin"
    include MiqAeServiceInflectorMixin
    require_relative "mixins/miq_ae_service_custom_attribute_mixin"
    include MiqAeServiceCustomAttributeMixin
    require_relative "mixins/miq_ae_external_url_mixin"
    include MiqAeExternalUrlMixin

    expose :to_s
    expose :authentication_userid
    expose :authentication_password
    expose :authentication_password_encrypted
    expose :authentication_key
    expose :refresh, :method => :refresh_ems
  end
end
