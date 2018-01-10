module MiqAeEngine
  class MiqAeInternalMethod
    DEFAULT_ATTR_NAME = 'result'.freeze
    DEFAULT_RETRY_INTERVAL = 1.minute

    def initialize(method_ar_obj, obj, inputs)
      @workspace     = obj.workspace
      @inputs        = inputs
      @method_ar_obj = method_ar_obj
      @ae_object     = obj
    end

    def run
      validate_args
      obj = resolved_target || resolved_class
      method = @method_ar_obj.options[:method].to_sym
      raise MiqAeException::MethodNotFound, "#{method} not defined for object #{obj}" unless obj.respond_to?(method)
      run_method(obj, method)
    end

    private

    def resolved_target
      if @method_ar_obj.options[:target]
        @ae_object.substitute_value(@method_ar_obj.options[:target], nil, true).tap do |value|
          raise ArgumentError, "Target #{@method_ar_obj.options[:target]} resolved to empty string" if value.blank?
        end
      end
    end

    def resolved_class
      @method_ar_obj.options[:target_class].constantize
    end

    def run_method(obj, method)
      process_result(call(obj, method))
      @workspace.root['ae_result'] = 'ok' if in_state?
    rescue MiqAeException::MiqAeRetryException
      set_retry if @method_ar_obj.options[:output_parameters].fetch(:retry_exception, false) && in_state?
    rescue StandardError => err
      error_handler(err)
    end

    def call(obj, method)
      @inputs.blank? ? obj.send(method) : obj.send(method, @inputs)
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
      if @method_ar_obj.options[:target].blank? && @method_ar_obj.options[:target_class].blank?
        raise MiqAeException::MethodParmMissing, "need a target or a target_class to execute the internal method"
      end

      raise MiqAeException::MethodParmMissing, "method name not provided" if @method_ar_obj.options[:method].blank?
    end

    def process_result(result)
      output_params = @method_ar_obj.options[:output_parameters]
      if output_params
        if output_params[:result_obj] == 'state_var'
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
      result_object[key || DEFAULT_ATTR_NAME] = value
    end

    def result_object
      obj_name = @method_ar_obj.options[:output_parameters][:result_obj] || '.'
      @workspace.get_obj_from_path(obj_name).tap do |obj|
        raise MiqAeException::ObjectNotFound, "Internal method results, object #{obj_name} missing" unless obj
      end
    end

    def set_retry
      @workspace.root['ae_result'] = 'retry'
      @workspace.root['ae_retry_interval'] = @method_ar_obj.options[:output_parameters].fetch(:retry_interval, DEFAULT_RETRY_INTERVAL)
    end

    def in_state?
      @workspace.root['ae_state_started'].present?
    end
  end
end
