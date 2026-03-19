module MiqAeMethodService
  class MiqAeServiceUser < MiqAeServiceModelBase
    require_relative "mixins/miq_ae_service_custom_attribute_mixin"
    include MiqAeServiceCustomAttributeMixin
    require_relative "mixins/miq_ae_external_url_mixin"
    include MiqAeExternalUrlMixin

    expose :current_tenant, :association => true
    expose :name
    expose :email
    expose :userid
    expose :ldap_group

    def role
      ar_method { @object.role.nil? ? nil : @object.role.name }
    end

    def get_ldap_attribute_names
      $miq_ae_logger.warn("[REMOVED] #{self.class.name}#get_ldap_attribute_names has been removed. Please use the net-ldap gem directly instead. At #{caller(1..1).first}")
      []
    end

    def get_ldap_attribute(name)
      $miq_ae_logger.warn("[REMOVED] #{self.class.name}#get_ldap_attribute has been removed. Please use the net-ldap gem directly instead. At #{caller(1..1).first}")
      nil
    end

    def miq_group
      $miq_ae_logger.warn("[DEPRECATION] #{self.class.name}#miq_group accessor is deprecated. Please use current_group instead. At #{caller(1..1).first}")
      current_group
    end
  end
end
