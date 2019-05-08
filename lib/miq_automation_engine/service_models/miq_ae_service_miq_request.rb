module MiqAeMethodService
  class MiqAeServiceMiqRequest < MiqAeServiceModelBase
    require_relative "mixins/miq_ae_service_miq_request_mixin"
    include MiqAeServiceMiqRequestMixin
    require_relative "mixins/miq_ae_service_dialog_option_mixin"
    include MiqAeServiceDialogOptionMixin

    expose :miq_request_tasks, :association => true
    expose :resource,          :association => true
    expose :authorized?
    expose :approve,   :override_return => true
    expose :deny,      :override_return => true
    expose :pending,   :override_return => true
    expose :cancel_requested?
    expose :canceling?
    expose :canceled?

    # For backward compatibility
    def miq_request
      self
    end
    association :miq_request

    def approvers
      ar_method { wrap_results @object.miq_approvals.collect { |a| a.approver.kind_of?(User) ? a.approver : nil }.compact }
    end
    association :approvers

    def set_message(value)
      object_send(:update_attributes, :message => value.try!(:truncate, 255))
    end

    def description=(new_description)
      object_send(:update_attributes, :description => new_description)
    end

    def show_url
      URI.join(MiqRegion.my_region.remote_ui_url, "miq_request/show/#{@object.id}").to_s
    end
  end
end
