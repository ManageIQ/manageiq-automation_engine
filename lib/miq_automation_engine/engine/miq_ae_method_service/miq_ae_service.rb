require_relative './miq_ae_service_model_legacy'
require_relative './miq_ae_service_vmdb'
require_relative './miq_ae_service_rbac'
module MiqAeMethodService
  class MiqAeService
    include Vmdb::Logging
    include DRbUndumped
    include MiqAeMethodService::MiqAeServiceModelLegacy
    include MiqAeMethodService::MiqAeServiceVmdb
    include MiqAeMethodService::MiqAeServiceRbac

    attr_accessor :logger

    @@id_hash = {}
    @@current = []

    def self.current
      @@current.last
    end

    def self.find(id)
      @@id_hash[id.to_i]
    end

    def self.add(obj)
      @@id_hash[obj.object_id] = obj
      @@current << obj
    end

    def self.destroy(obj)
      @@id_hash.delete(obj.object_id)
      @@current.delete(obj)
    end

    def initialize(workspace, inputs = {}, logger = $miq_ae_logger)
      @tracking_label        = Thread.current["tracking_label"]
      @drb_server_references = []
      @inputs                = inputs
      @workspace             = workspace
      @persist_state_hash    = workspace.persist_state_hash
      @logger                = logger
      self.class.add(self)
      workspace.disable_rbac
    end

    delegate :enable_rbac, :disable_rbac, :rbac_enabled?, :to => :@workspace

    def stdout
      @stdout ||= Vmdb::Loggers::IoLogger.new(logger, :info, "Method STDOUT:")
    end

    def stderr
      @stderr ||= Vmdb::Loggers::IoLogger.new(logger, :error, "Method STDERR:")
    end

    def destroy
      self.class.destroy(self)
    end

    def disconnect_sql
      ActiveRecord::Base.connection_pool.release_connection
    end

    attr_writer :inputs

    attr_reader :inputs

    ####################################################

    def log(level, msg)
      Thread.current["tracking_label"] = @tracking_label
      $miq_ae_logger.send(level, "<AEMethod #{current_method}> #{ManageIQ::Password.sanitize_string(msg)}", :resource_id => @workspace.find_miq_request_id)
    end

    def set_state_var(name, value)
      @persist_state_hash[name] = value
    end

    def state_var_exist?(name)
      @persist_state_hash.key?(name)
    end

    def get_state_var(name)
      @persist_state_hash[name]
    end

    def delete_state_var(name)
      @persist_state_hash.delete(name)
    end

    def get_state_vars
      @persist_state_hash
    end

    def ansible_stats_vars
      MiqAeEngine::MiqAeAnsibleMethodBase.ansible_stats_from_hash(@persist_state_hash)
    end

    def set_service_var(name, value)
      if service_object.nil?
        $miq_ae_logger.error("Service object not found in root object, set_service_var skipped for #{name} = #{value}", :resource_id => @workspace.find_miq_request_id)
        return
      end

      service_object.root_service.set_service_vars_option(name, value)
    end

    def service_var_exists?(name)
      return false unless service_object

      service_object.root_service.service_vars_options.key?(name)
    end

    def get_service_var(name)
      return unless service_var_exists?(name)

      service_object.root_service.get_service_vars_option(name)
    end

    def delete_service_var(name)
      return unless service_var_exists?(name)

      service_object.root_service.delete_service_vars_option(name)
    end

    def instantiate(uri)
      obj = @workspace.instantiate(uri, @workspace.ae_user, @workspace.current_object)
      return nil if obj.nil?

      MiqAeServiceObject.new(obj, self)
    rescue StandardError => e
      $miq_ae_logger.error("instantiate failed : #{e.message}", :resource_id => @workspace.find_miq_request_id)
      nil
    end

    def object(path = nil)
      obj = @workspace.get_obj_from_path(path)
      return nil if obj.nil?

      MiqAeServiceObject.new(obj, self)
    end

    def hash_to_query(hash)
      MiqAeEngine::MiqAeUri.hash2query(hash)
    end

    def query_to_hash(query)
      MiqAeEngine::MiqAeUri.query2hash(query)
    end

    def current_namespace
      @workspace.current_namespace
    end

    def current_class
      @workspace.current_class
    end

    def current_instance
      @workspace.current_instance
    end

    def current_message
      @workspace.current_message
    end

    def current_object
      @current_object ||= MiqAeServiceObject.new(@workspace.current_object, self)
    end

    def current_method
      @workspace.current_method
    end

    def current
      current_object
    end

    def root
      @root ||= object("/")
    end

    def parent
      @parent ||= object("..")
    end

    def objects(aobj)
      aobj.collect do |obj|
        obj = MiqAeServiceObject.new(obj, self) unless obj.kind_of?(MiqAeServiceObject)
        obj
      end
    end

    def datastore
    end

    def ldap
    end

    def execute(method_name, *args, **kwargs, &block)
      User.with_user(@workspace.ae_user) { execute_with_user(method_name, *args, **kwargs, &block) }
    end

    def execute_with_user(method_name, *args, **kwargs, &block)
      # Since each request from DRb client could run in a separate thread
      # We have to set the current_user in every thread.

      # For ruby 2.6-3.0+ support, we grab any kwargs and append as a hash
      # at the end of the args, as all MiqAeServiceMethods now don't accept
      # kwargs.  When we get to ruby 3, we can remove this and convert all to
      # kwargs.
      args << kwargs unless kwargs.blank?
      MiqAeServiceMethods.send(method_name, *args, &block)
    rescue NoMethodError => err
      raise MiqAeException::MethodNotFound, err.message
    end

    def notification_subject(values_hash)
      subject = values_hash[:subject] || @workspace.ae_user
      (ar_object(subject) || subject).tap do |object|
        raise ArgumentError, "Subject must be a valid Active Record object" unless object.kind_of?(ActiveRecord::Base)
      end
    end

    def ar_object(svc_obj)
      if svc_obj.kind_of?(MiqAeMethodService::MiqAeServiceModelBase)
        svc_obj.instance_variable_get('@object')
      end
    end

    def notification_type(values_hash)
      type = values_hash[:type].present? ? values_hash[:type].to_sym : default_notification_type(values_hash)
      type.tap do |t|
        $miq_ae_logger.info("Validating Notification type: #{t}", :resource_id => @workspace.find_miq_request_id)
        valid_type = NotificationType.find_by(:name => t)
        raise ArgumentError, "Invalid notification type specified" unless valid_type
      end
    end

    def create_notification(values_hash = {})
      create_notification!(values_hash)
    rescue StandardError
      nil
    end

    def create_notification!(values_hash = {})
      User.with_user(@workspace.ae_user) { create_notification_with_user!(values_hash) }
    end

    def create_notification_with_user!(values_hash)
      options = {}
      type = notification_type(values_hash)
      subject = notification_subject(values_hash)
      options[:message] = values_hash[:message] if values_hash[:message].present?

      $miq_ae_logger.info("Calling Create Notification type: #{type} subject type: #{subject.class.base_class.name} id: #{subject.id} options: #{options.inspect}", :resource_id => @workspace.find_miq_request_id)
      MiqAeServiceModelBase.wrap_results(Notification.create!(:type      => type,
                                                              :subject   => subject,
                                                              :options   => options,
                                                              :initiator => @workspace.ae_user))
    end

    def instance_exists?(path)
      _log.info("<< path=#{path.inspect}")
      !!__find_instance_from_path(path)
    end

    def instance_create(path, values_hash = {})
      _log.info("<< path=#{path.inspect}, values_hash=#{values_hash.inspect}")

      return false unless editable_instance?(path)

      ns, klass, instance = MiqAeEngine::MiqAePath.split(path)
      $miq_ae_logger.info("Instance Create for ns: #{ns} class #{klass} instance: #{instance}", :resource_id => @workspace.find_miq_request_id)

      aec = MiqAeClass.lookup_by_namespace_and_name(ns, klass)
      return false if aec.nil?

      aei = aec.ae_instances.detect { |i| instance.casecmp(i.name).zero? }
      return false unless aei.nil?

      aei = MiqAeInstance.create(:name => instance, :class_id => aec.id)
      values_hash.each { |key, value| aei.set_field_value(key, value) }

      true
    end

    def instance_get_display_name(path)
      _log.info("<< path=#{path.inspect}")
      aei = __find_instance_from_path(path)
      aei.try(:display_name)
    end

    def instance_set_display_name(path, display_name)
      _log.info("<< path=#{path.inspect}, display_name=#{display_name.inspect}")
      aei = __find_instance_from_path(path)
      return false if aei.nil?

      aei.update(:display_name => display_name)
      true
    end

    def instance_update(path, values_hash)
      _log.info("<< path=#{path.inspect}, values_hash=#{values_hash.inspect}")
      return false unless editable_instance?(path)

      aei = __find_instance_from_path(path)
      return false if aei.nil?

      values_hash.each { |key, value| aei.set_field_value(key, value) }
      true
    end

    def instance_find(path, options = {})
      _log.info("<< path=#{path.inspect}")
      result = {}

      ns, klass, instance = MiqAeEngine::MiqAePath.split(path)
      aec = MiqAeClass.lookup_by_namespace_and_name(ns, klass)
      unless aec.nil?
        instance.gsub!(".", '\.')
        instance.gsub!("*", ".*")
        instance.gsub!("?", ".{1}")
        instance_re = Regexp.new("^#{instance}$", Regexp::IGNORECASE)

        aec.ae_instances.select { |i| instance_re =~ i.name }.each do |aei|
          iname = if options[:path]
                    aei.fqname
                  else
                    aei.name
                  end
          result[iname] = aei.field_attributes
        end
      end

      result
    end

    def instance_get(path)
      _log.info("<< path=#{path.inspect}")
      aei = __find_instance_from_path(path)
      return nil if aei.nil?

      aei.field_attributes
    end

    def instance_delete(path)
      _log.info("<< path=#{path.inspect}")
      return false unless editable_instance?(path)

      aei = __find_instance_from_path(path)
      return false if aei.nil?

      aei.destroy
      true
    end

    def __find_instance_from_path(path)
      dom, ns, klass, instance = MiqAeEngine::MiqAePath.get_domain_ns_klass_inst(path)
      return false unless visible_domain?(dom)

      aec = MiqAeClass.lookup_by_namespace_and_name("#{dom}/#{ns}", klass)
      return nil if aec.nil?

      aec.ae_instances.detect { |i| instance.casecmp(i.name).zero? }
    end

    def field_timeout
      raise _("ae_state_max_retries is not set in automate field") if root['ae_state_max_retries'].blank?

      interval = root['ae_retry_interval'].present? ? root['ae_retry_interval'].to_i_with_method : 1
      interval * root['ae_state_max_retries'].to_i
    end

    private

    def service_object
      current['service'] || root['service']
    end

    def editable_instance?(path)
      dom, = MiqAeEngine::MiqAePath.get_domain_ns_klass_inst(path)
      return false unless owned_domain?(dom)

      domain = MiqAeDomain.lookup_by_fqname(dom, false)
      return false unless domain

      $miq_ae_logger.warn("path=#{path.inspect} : is not editable", :resource_id => @workspace.find_miq_request_id) unless domain.editable?(@workspace.ae_user)
      domain.editable?(@workspace.ae_user)
    end

    def owned_domain?(dom)
      domains = @workspace.ae_user.current_tenant.ae_domains.collect(&:name).map(&:upcase)
      return true if domains.include?(dom.upcase)

      $miq_ae_logger.warn("domain=#{dom} : is not editable", :resource_id => @workspace.find_miq_request_id)
      false
    end

    def visible_domain?(dom)
      domains = @workspace.ae_user.current_tenant.visible_domains.collect(&:name).map(&:upcase)
      return true if domains.include?(dom.upcase)

      $miq_ae_logger.warn("domain=#{dom} : is not viewable", :resource_id => @workspace.find_miq_request_id)
      false
    end

    def default_notification_type(values_hash)
      level = values_hash[:level] || "info"
      audience = values_hash[:audience] || "user"
      "automate_#{audience}_#{level}".downcase.to_sym
    end
  end
end
