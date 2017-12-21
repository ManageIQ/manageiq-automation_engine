module MiqAeEngine
  class MiqAeInternalMethod
    DEFAULT_ATTR_NAME = 'result'.freeze
    DEFAULT_RETRY_INTERVAL = 1.minute

    def initialize(aem, obj, inputs)
      @workspace = obj.workspace
      @inputs    = inputs
      @aem       = aem
      @ae_object = obj
    end

    def run
      validate_args
      obj = resolved_object || @aem.options[:class].constantize
      run_method(obj, @aem.options[:method].to_sym)
    end

    private

    def resolved_object
      if @aem.options[:object]
        @ae_object.substitute_value(@aem.options[:object], nil, true).tap do |value|
          raise ArgumentError, "Object #{@aem.options[:object]} resolved to empty string" if value.blank?
        end
      end
    end

    def run_method(obj, method)
      if obj.respond_to?(method)
        process_result(@inputs.blank? ? obj.send(method) : obj.send(method, @inputs))
        @workspace.root['ae_result'] = 'ok' if in_state?
      else
        raise MiqAeException::MethodNotFound, "#{method} not defined for object #{obj}"
      end
    rescue MiqAeException::MiqAeRetryException
      set_retry if @aem.options[:output_parameters].fetch(:retry_exception, false) && in_state?
    rescue StandardError => err
      error_handler(err)
    end

    def error_handler(err)
      $miq_ae_logger.error("Internal method failed. error  #{err.message}")
      if in_state?
        @workspace.root['ae_result'] = 'error'
      else
        raise err
      end
    end

    def validate_args
      if @aem.options[:object].blank? && @aem.options[:class].blank?
        raise MiqAeException::MethodParmMissing, "need an object or a class to execute the internal method"
      end

      raise MiqAeException::MethodParmMissing, "method name not provided" if @aem.options[:method].blank?
    end

    def process_result(result)
      output_params = @aem.options[:output_parameters]
      if output_params
        if output_params[:result_object] == 'state_var'
          set_state_var(result, output_params[:result_attr])
        else
          set_object_attribute(result, output_params[:result_attr])
        end
      end
    end

    def set_state_var(result, key)
      key, value = MiqAeEngine.create_automation_attribute(key, result)
      @workspace.set_state_var(key || DEFAULT_ATTR_NAME, value)
    end

    def set_object_attribute(result, key)
      value = if result.kind_of?(ActiveRecord::Base)
                MiqAeMethodService::MiqAeServiceModelBase.wrap_results(result)
              else
                result
              end
      target_object[key || DEFAULT_ATTR_NAME] = value
    end

    def target_object
      obj_name = @aem.options[:output_parameters][:result_object] || '.'
      @workspace.get_obj_from_path(obj_name).tap do |obj|
        raise MiqAeException::ObjectNotFound, "Internal method results, object #{obj_name} missing" unless obj
      end
    end

    def set_retry
      @workspace.root['ae_result'] = 'retry'
      @workspace.root['ae_retry_interval'] = @aem.options[:output_parameters].fetch(:retry_interval, DEFAULT_RETRY_INTERVAL)
    end

    def in_state?
      @workspace.root['ae_state_started'].present?
    end
  end
end
