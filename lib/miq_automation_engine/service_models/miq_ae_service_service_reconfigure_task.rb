module MiqAeMethodService
  class MiqAeServiceServiceReconfigureTask < MiqAeServiceMiqRequestTask
    expose :statemachine_task_status

    def dialog_options
      options[:dialog] || {}
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

    def finished(msg)
      object_send(:update_and_notify_parent, :state => 'finished', :message => msg)
    end
  end
end
