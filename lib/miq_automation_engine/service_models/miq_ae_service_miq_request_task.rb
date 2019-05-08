module MiqAeMethodService
  class MiqAeServiceMiqRequestTask < MiqAeServiceModelBase
    require_relative "mixins/miq_ae_service_miq_request_mixin"
    include MiqAeServiceMiqRequestMixin
    require_relative "mixins/miq_ae_service_dialog_option_mixin"
    include MiqAeServiceDialogOptionMixin

    expose :execute, :method => :execute_queue, :override_return => true
    expose :cancel_requested?
    expose :canceling?
    expose :canceled?

    undef :phase_context

    def message=(msg)
      ar_method { @object.update_and_notify_parent(:message => msg) unless @object.state == 'finished' }
    end

    def finished(msg)
      object_send(:update_and_notify_parent, :state => 'finished', :message => msg)
    end

    def status
      $miq_ae_logger.warn("[DEPRECATION] status method is deprecated.  Please use statemachine_task_status instead.")
      statemachine_task_status
    end
  end
end
