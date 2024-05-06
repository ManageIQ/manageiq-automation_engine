module MiqAeMethodService
  class MiqAeServiceServiceTemplateProvisionTask < MiqAeServiceMiqRequestTask
    expose :provision_priority
    expose :statemachine_task_status

    def dialog_options
      options[:dialog] || {}
    end

    def get_dialog_option(key)
      dialog_options[key]
    end

    def group_sequence_run_now?
      ar_method { @object.group_sequence_run_now? }
    end

    def set_dialog_option(key, value)
      ar_method do
        @object.options[:dialog] ||= {}
        @object.options[:dialog][key] = value
        @object.update_attribute(:options, @object.options)
      end
    end

    def provisioned(msg)
      object_send(:update_and_notify_parent, :state => 'provisioned', :message => msg)
    end
  end
end
