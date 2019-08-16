module MiqAeMethodService
  class MiqAeServiceTenant < MiqAeServiceModelBase
    require_relative "mixins/miq_ae_external_url_mixin"
    include MiqAeExternalUrlMixin
  end
end
