module MiqAeEngine
  class MiqAeExpressionMethod
    include MiqExpression::SubstMixin
    def initialize(method_obj, obj, inputs)
      @edit = {}
      @name = method_obj.name
      @workspace = obj.workspace
      @inputs = inputs
      @attributes = inputs['distinct'] || inputs['attributes'] || %w[name]
      load_expression(method_obj.data)
      process_filter
    end

    def run
      @search_objects = Rbac.filtered(@exp_object, :filter => MiqExpression.new(@exp))
      @search_objects.empty? ? error_handler : set_result
    end

    private

    def load_expression(data)
      raise MiqAeException::MethodExpressionEmpty, "Empty expression" if data.blank?

      begin
        hash = YAML.load(data)
        if hash[:expression] && hash[:db]
          @exp = hash[:expression]
          @exp_object = hash[:db]
        else
          raise MiqAeException::MethodExpressionInvalid, "Invalid expression #{data}"
        end
      rescue StandardError
        raise MiqAeException::MethodExpressionInvalid, "Invalid expression #{data}"
      end
    end

    def process_filter
      exp_table = exp_build_table(@exp, true)
      qs_tokens = create_tokens(exp_table, @exp)
      values = get_args(qs_tokens.keys.length)
      qs_tokens.keys.each_with_index { |token_at, index| qs_tokens[token_at][:value] = values[index] }
      exp_replace_qs_tokens(@exp, qs_tokens)
    end

    def result_hash(obj)
      @attributes.each_with_object({}) do |attr, hash|
        hash[attr] = result_simple(obj, attr)
      end
    end

    def result_array
      multiple = @attributes.count > 1
      result = @search_objects.collect do |obj|
        multiple ? @attributes.collect { |attr| result_simple(obj, attr) } : result_simple(obj, @attributes.first)
      end
      @inputs['distinct'].blank? ? result : result.uniq
    end

    def result_dialog_hash
      key = @inputs['key'] || 'id'
      @search_objects.each_with_object({}) do |obj, hash|
        hash[result_simple(obj, key)] = result_simple(obj, @attributes.first)
      end
    end

    def result_simple(obj, attr)
      raise MiqAeException::MethodNotDefined, "Undefined method #{attr} in class #{obj.class}" unless obj.respond_to?(attr.to_sym)

      obj.send(attr.to_sym)
    end

    def set_result
      target_object.attributes[attribute_name] = exp_value
      @workspace.root['ae_result'] = 'ok'
    end

    def error_handler
      disposition = @inputs['on_empty'] || 'error'
      case disposition.to_sym
      when :error
        set_error
      when :warn
        set_warn
      when :abort
        set_abort
      end
    end

    def set_error
      $miq_ae_logger.error("Expression method ends")
      @workspace.root['ae_result'] = 'error'
    end

    def set_abort
      $miq_ae_logger.error("Expression method aborted")
      raise MiqAeException::AbortInstantiation, "Expression method #{@name} aborted"
    end

    def set_warn
      $miq_ae_logger.warn("Expression method ends")
      @workspace.root['ae_result'] = 'warn'
      set_default_value
    end

    def set_default_value
      return unless @inputs.key?('default')

      target_object.attributes[attribute_name] = @inputs['default']
    end

    def attribute_name
      @inputs['result_attr'] || 'values'
    end

    def target_object
      @workspace.get_obj_from_path(@inputs['result_obj'] || '.').tap do |obj|
        raise MiqAeException::MethodExpressionTargetObjectMissing, @inputs['result_obj'] unless obj
      end
    end

    def exp_value
      type = @inputs['result_type'] || 'dialog_hash'
      case type.downcase.to_sym
      when :hash
        result_hash(@search_objects.first)
      when :dialog_hash
        result_dialog_hash
      when :array
        result_array
      when :simple
        result_simple(@search_objects.first, @inputs['attributes'].first)
      else
        raise MiqAeException::MethodExpressionResultTypeInvalid, "Invalid Result type, should be hash, array or dialog_hash"
      end
    end

    def get_args(num_token)
      params = []
      (1..num_token).each do |i|
        key = "arg#{i}"
        raise MiqAeException::MethodParameterNotFound, key unless @inputs.key?(key)

        params[i - 1] = @inputs[key]
      end
      params
    end
  end
end
