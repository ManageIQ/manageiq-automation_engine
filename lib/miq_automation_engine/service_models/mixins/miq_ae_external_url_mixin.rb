module MiqAeExternalUrlMixin
  extend ActiveSupport::Concern
  def external_url=(url)
    object_send(:external_url=, url, MiqAeEngine::DrbRemoteInvoker.workspace.ae_user)
  end
end
