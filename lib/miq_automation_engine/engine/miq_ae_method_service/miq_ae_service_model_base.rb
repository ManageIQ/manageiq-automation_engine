require_relative 'miq_ae_service_object_common'
require_relative 'miq_ae_service_rbac'
module MiqAeMethodService
  class MiqAeServiceModelBase
    SERVICE_MODEL_PATH = ManageIQ::AutomationEngine::Engine.root.join("lib", "miq_automation_engine", "service_models")
    EXPOSED_ATTR_BLACK_LIST = [/password/, /^auth_key$/].freeze
    NORMALIZED_PREFIX = 'normalized_'.freeze
    class << self
      include DRbUndumped  # Ensure that Automate Method can get at the class itself over DRb
    end

    include DRbUndumped    # Ensure that Automate Method can get at instances over DRb
    include MiqAeMethodService::MiqAeServiceObjectCommon
    include Vmdb::Logging
    include MiqAeMethodService::MiqAeServiceRbac

    def self.method_missing(method_name, *args)
      return wrap_results(filter_objects(model.send(method_name, *args))) if class_method_exposed?(method_name)

      super
    rescue ActiveRecord::RecordNotFound
      raise MiqAeException::ServiceNotFound, "Service Model not found"
    end

    def self.respond_to_missing?(method_name, include_private = false)
      class_method_exposed?(method_name.to_sym) || super
    end

    def self.allowed_find_method?(method_name)
      return false if method_name.starts_with?('find_or_create') || method_name.starts_with?('find_or_initialize')

      method_name.starts_with?('find', 'lookup_by')
    end

    # Expose the ActiveRecord find, all, count, and first
    def self.class_method_exposed?(method_name)
      allowed_find_method?(method_name.to_s) || [:where, :find].include?(method_name)
    end

    private_class_method :class_method_exposed?
    private_class_method :allowed_find_method?

    def self.inherited(subclass)
      # Skip for anonymous classes
      return unless subclass.name

      expose_class_attributes(subclass)
      expose_class_associations(subclass)
    end

    def self.expose_class_associations(subclass)
      subclass.class_eval do
        ar_model_associations.each { |key| expose(key, :association => true) }
      end
    end

    def self.ar_model_associations
      model.reflections_with_virtual.except(:tags).keys - superclass_associations
    end

    def self.expose_class_attributes(subclass)
      subclass.class_eval do
        model.attribute_names.each do |attr|
          next if model.private_method_defined?(attr)
          next if EXPOSED_ATTR_BLACK_LIST.any? { |rexp| attr =~ rexp }
          next if subclass.base_class != self && method_defined?(attr)

          expose attr
        end
      end
    end

    def self.associations
      (superclass_associations + @associations ||= []).sort
    end

    def self.superclass_associations
      superclass.try(:associations) || []
    end

    def associations
      self.class.associations
    end

    def self.association(*args)
      args.each { |method_name| self.association = method_name }
    end

    def self.association=(meth)
      @associations ||= []
      @associations << meth.to_s unless associations.include?(meth.to_s)
    end

    def self.base_class
      @base_class ||= begin
        model_name_from_active_record_model(model.base_class).constantize
      end
    end

    def self.base_model
      @base_model ||= begin
        model_name_from_active_record_model(model.base_model).constantize
      end
    end

    def self.model
      # Set a class-instance variable to get the appropriate model
      @model ||= /MiqAeService(.+)$/.match(name)[1].gsub(/_/, '::').constantize
    end
    private_class_method :model

    def self.model_name_from_active_record_model(ar_model)
      "MiqAeMethodService::MiqAeService#{ar_model.name.gsub(/::/, '_')}"
    end

    def self.create_service_model_from_name(name)
      backing_model = service_model_name_to_model(name)

      create_service_model(backing_model) if ar_model?(backing_model)
    end

    def self.create_service_model(ar_model)
      file_path = model_to_file_path(ar_model)
      if File.exist?(file_path)
        # class reloading in development causes require to no-op when it should load
        # since we will never require this file, using load is not a big loss
        load file_path
        model_name_from_active_record_model(ar_model).safe_constantize
      else
        dynamic_service_model_creation(ar_model, service_model_superclass(ar_model))
      end
    end
    private_class_method :create_service_model

    def self.dynamic_service_model_creation(ar_model, super_class)
      Class.new(super_class) do |klass|
        ::MiqAeMethodService.const_set(model_to_service_model_name(ar_model), klass)
        expose_class_attributes(klass)
        expose_class_associations(klass)
      end
    end
    private_class_method :dynamic_service_model_creation

    def self.service_model_superclass(ar_model)
      return self if ar_model.superclass == ApplicationRecord

      model_name_from_active_record_model(ar_model.superclass).safe_constantize
    end
    private_class_method :service_model_superclass

    def self.ar_model?(the_model)
      return false unless the_model

      the_model < ApplicationRecord || false
    end

    def self.service_model_name_to_model(service_model_name)
      ar_model_name = /MiqAeService(.+)$/.match(service_model_name)
      return if ar_model_name.nil?

      ar_model_name[1].gsub(/_/, '::').safe_constantize
    end

    def self.model_to_service_model_name(ar_model)
      "MiqAeService#{ar_model.name.gsub(/::/, '_')}"
    end

    def self.model_to_file_name(ar_model)
      "miq_ae_service_#{ar_model.name.underscore.tr('/', '-')}.rb"
    end

    def self.model_to_file_path(ar_model)
      File.join(SERVICE_MODEL_PATH, model_to_file_name(ar_model))
    end

    def self.ar_base_model
      send(:model).base_model
    end

    def self.expose(*args)
      raise ArgumentError, "must pass at least one method name" if args.empty? || args.first.kind_of?(Hash)

      options = args.last.kind_of?(Hash) ? args.pop : {}
      raise ArgumentError, "cannot have :method option if there is more than one method name specified" if options.key?(:method) && args.length != 1

      args.each do |method_name|
        next if method_name.to_sym == :id

        self.association = method_name if options[:association]
        define_method(method_name) do |*params|
          method = options[:method] || method_name
          ret = User.with_user(self.class.workspace&.ae_user) { object_send(method, *params) }
          return options[:override_return] if options.key?(:override_return)

          options[:association] ? wrap_results(self.class.filter_objects(ret)) : wrap_results(ret)
        end
      end
    end
    private_class_method :expose

    def self.workspace
      MiqAeEngine::MiqAeWorkspaceRuntime.current || MiqAeEngine::DrbRemoteInvoker.workspace
    end

    def self.wrap_results(results)
      ar_method do
        if results.kind_of?(Array) || results.kind_of?(ActiveRecord::Relation)
          results.collect { |r| wrap_results(r) }
        elsif results.kind_of?(ActiveRecord::Base)
          klass = MiqAeMethodService.const_get("MiqAeService#{results.class.name.gsub(/::/, '_')}")
          klass.new(results)
        else
          results
        end
      end
    end

    def wrap_results(results)
      self.class.wrap_results(results)
    end

    #
    # Convert URI Excluded US-ASCII Characters to underscores
    #
    # The following is a synopsis of section 2.4.3 from http://www.ietf.org/rfc/rfc2396.txt
    #   control     = <US-ASCII coded characters 00-1F and 7F hexadecimal>
    #   space       = <US-ASCII coded character 20 hexadecimal>
    #   delims      = "<" | ">" | "#" | "%" | <">
    #   unwise      = "{" | "}" | "|" | "\" | "^" | "[" | "]" | "`"
    #
    DELIMS = ['<', '>', '#', '%', "\""].freeze
    UNWISE = ['{', '}', '|', "\\", '^', '[', ']', "\`"].freeze
    def self.normalize(str)
      return str unless str.kind_of?(String)

      arr = str.each_char.collect do |c|
        if DELIMS.include?(c) || UNWISE.include?(c) || c == ' '
          '_'
        else
          ordinal = c.ord
          if (ordinal >= 0x00 && ordinal <= 0x1F) || ordinal == 0x7F
            '_'
          else
            c
          end
        end
      end

      arr.join
    end

    def method_missing(method_name, *args)
      #
      # Normalize result of any method call
      #  e.g. normalized_ldap_group, will call ldap_group method and normalize the result
      #
      if method_name.to_s.starts_with?(NORMALIZED_PREFIX)
        method = method_name.to_s[NORMALIZED_PREFIX.length..-1]
        result = MiqAeServiceModelBase.wrap_results(object_send(method, *args))
        return MiqAeServiceModelBase.normalize(result)
      end

      super
    end

    def respond_to_missing?(method_name, include_private = false)
      if method_name.to_s.start_with?(NORMALIZED_PREFIX)
        method_n = method_name.to_s[NORMALIZED_PREFIX.length..-1]
        return object_send(:respond_to?, method_n, include_private)
      end

      super
    end

    def self.find_miq_request_id(object)
      if !defined?(object.type).nil?
        if object.type.to_s.include?("RequestEvent")
          return object.target_id
        elsif object.type.to_s.include?("Request")
          return object.id
        elsif object.type.to_s.include?("Task")
          return object.miq_request_id
        end
      end
      nil
    end

    # @param obj [Integer,ActiveRecord::Base] The object id or ActiveRecord instance to wrap
    #   in a service model
    def initialize(obj)
      ar_klass = self.class.send(:model)
      raise ArgumentError, "#{ar_klass.name} Nil Object specified" if obj.nil?
      if obj.kind_of?(ActiveRecord::Base) && !obj.kind_of?(ar_klass)
        raise ArgumentError, "#{ar_klass.name} Object expected, but received #{obj.class.name}"
      end

      @object = obj.kind_of?(ar_klass) ? obj : self.class.ar_method { ar_klass.find_by(:id => obj) }
      raise MiqAeException::ServiceNotFound, "#{ar_klass.name} Object [#{obj}] not found" if @object.nil?
    end

    def virtual_columns_inspect
      arr = @object.class.virtual_attribute_names.sort.collect { |vc| "#{vc}: #{@object.send(vc).inspect}" }
      "<#{arr.join(', ')}>"
    end

    def virtual_column_names
      @object.class.virtual_attribute_names.sort
    end

    def inspect
      ar_method { "\#<#{self.class.name.demodulize}:0x#{object_id.to_s(16)} @object=#{@object.inspect}, @virtual_columns=#{virtual_column_names.inspect}, @associations=#{associations.inspect}>" }
    end

    def inspect_all
      ar_method { "\#<#{self.class.name.demodulize}:0x#{object_id.to_s(16)} @object=#{@object.inspect}, @virtual_columns=#{virtual_columns_inspect}, @associations=#{associations.inspect}>" }
    end

    def tagged_with?(category, name)
      verify_taggable_model
      object_send(:is_tagged_with?, name.to_s, :ns => "/managed/#{category}")
    end

    def tags(category = nil)
      verify_taggable_model
      ns = category.nil? ? "/managed" : "/managed/#{category}"
      object_send(:tag_list, :ns => ns).split
    end

    def tag_assign(tag)
      verify_taggable_model
      ar_method do
        Classification.classify_by_tag(@object, "/managed/#{tag}")
        true
      end
    end

    def tag_unassign(tag)
      verify_taggable_model
      ar_method do
        Classification.unclassify_by_tag(@object, "/managed/#{tag}")
        true
      end
    end

    def taggable?
      self.class.taggable?
    end

    def self.taggable?
      model.respond_to?(:tags)
    end

    def reload
      raise ActiveRecord::RecordNotFound, "Couldn't find related ActiveRecord object" unless record_exists?

      object_send(:reload)
      self # Return self to prevent the internal object from being returned
    end

    def object_send(name, *params)
      ar_method do
        begin
          @object.public_send(name, *params)
        rescue Exception # rubocop:disable Lint/RescueException
          $miq_ae_logger.error("The following error occurred during instance method <#{name}> for AR object <#{@object.inspect}>", :resource_id => self.class.find_miq_request_id(@object))
          raise
        end
      end
    end

    def object_class
      object_send(:class)
    end

    def model_suffix
      @object.class.model_suffix
    end

    def self.ar_method
      # In UI Worker, query caching is enabled.  This causes problems in Automate DRb Server (e.g. reload does not refetch from SQL)
      ActiveRecord::Base.connection.clear_query_cache if ActiveRecord::Base.connection.query_cache_enabled
      yield
    rescue Exception => err # rubocop:disable Lint/RescueException
      miq_request_id = find_miq_request_id(@object)
      $miq_ae_logger.error("MiqAeServiceModelBase.ar_method raised: <#{err.class}>: <#{err.message}>", :resource_id => miq_request_id)
      $miq_ae_logger.error(err.backtrace.join("\n"), :resource_id => miq_request_id)
      raise
    ensure
      begin
        ActiveRecord::Base.connection_pool.release_connection
      rescue StandardError
        nil
      end
    end

    def ar_method(&block)
      return if @object.nil?

      self.class.ar_method(&block)
    end

    def ==(other)
      self.class == other.class && id == other.id
    end

    def encode_with(coder)
      coder['id'] = id
    end

    def init_with(coder)
      @object = self.class.service_model_name_to_model(self.class.name)&.find_by(:id => coder['id'])
      $miq_ae_logger.warn("There is no related active record object with id=#{coder['id']} for imported #{self.class}") if @object.nil?

      self
    end

    def record_exists?
      @object.present?
    end

    private

    def verify_taggable_model
      raise MiqAeException::UntaggableModel, "Model #{self.class} doesn't support tagging" unless taggable?
    end
  end
end
