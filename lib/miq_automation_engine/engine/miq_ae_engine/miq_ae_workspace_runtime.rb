require_relative 'miq_ae_state_info'
module MiqAeEngine
  class MiqAeWorkspaceRuntime
    attr_accessor :graph, :class_methods, :invoker
    attr_accessor :datastore_cache, :persist_state_hash, :current_state_info
    attr_accessor :ae_user
    include MiqAeStateInfo
    include MiqAeSerializeWorkspace
    include MiqAeDeserializeWorkspace
    include MiqAeObjectLookup

    attr_reader :nodes

    def initialize(options = {})
      @readonly          = options[:readonly] || false
      @nodes             = []
      @current           = []
      @datastore_cache   = {}
      @class_methods     = {}
      @dom_search        = MiqAeDomainSearch.new
      @persist_state_hash = StateVarHash.new
      @current_state_info = {}
      @state_machine_objects = []
      @ae_user = nil
      @rbac = false
      initialize_obj_entries
    end

    def readonly?
      @readonly
    end

    def self.current=(workspace)
      Thread.current[:current_workspace] = workspace
    end

    def self.current
      Thread.current[:current_workspace]
    end

    def self.clear_stored_workspace
      self.current = nil
    end

    def self.instantiate(uri, user, attrs = {})
      User.with_user(user) { instantiate_with_user(uri, user, attrs) }
    end

    def self.instantiate_with_user(uri, user, attrs)
      workspace = MiqAeWorkspaceRuntime.new(attrs)
      self.current = workspace
      workspace.instantiate(uri, user, nil)

      if !uri.nil?
        _scheme, _userinfo, _host, _port, _registry, _path, _opaque, query, _fragment = MiqAeUri.split(uri, "miqaedb")
        args = MiqAeUri.query2hash(query)
        miq_request_id = find_miq_request_id(args)
      else
        miq_request_id = nil
      end

      workspace
    rescue MiqAeException => err
      $miq_ae_logger.error(err.message, :resource_id => miq_request_id)
    ensure
      clear_stored_workspace
    end

    def self.find_miq_request_id(args)
      miq_request_id = nil
      if args['MiqRequest::miq_request']
        miq_request_id = args['MiqRequest::miq_request']
      elsif args['vmdb_object_type'].to_s.include?("task")
        current_task = nil
        MiqRequestTask.descendants.map(&:name).each do |task|
          if args.keys.any? { |k| k.include?(task) }
            current_task = task
            break
          end
        end

        if !current_task.nil?
          task_id_key = args.keys.find { |key| key.include?(current_task) }
          miq_request_id = current_task.constantize.find(args[task_id_key]).miq_request_id
        end
      end
      miq_request_id
    end

    def find_miq_request_id
      # TODO: get rid of defined
      if !defined?(root.attributes).nil?
        if !root.attributes['miq_request_id'].nil?
          root.attributes['miq_request_id']
        elsif !defined?(root.attributes[root.attributes['vmdb_object_type']].miq_request_id).nil?
          root.attributes[root.attributes['vmdb_object_type']].miq_request_id
        elsif !defined?(root.attributes[root.attributes['vmdb_object_type']].object.miq_request_id).nil?
          root.attributes[root.attributes['vmdb_object_type']].object.miq_request_id
        end
      end
    rescue => err
      $miq_ae_logger.error("Failed to find miq_request_id, in root.attributes: #{root.attributes.keys}")
      $miq_ae_logger.error(err)
      nil
    end

    def rbac_enabled?
      @rbac
    end

    def enable_rbac
      @rbac = true
    end

    def disable_rbac
      @rbac = false
    end

    DATASTORE_CACHE = true
    def datastore(klass, key)
      if DATASTORE_CACHE
        @datastore_cache[klass] ||= {}
        @datastore_cache[klass][key] = yield unless @datastore_cache[klass].key?(key)
        @datastore_cache[klass][key]
      else
        yield
      end
    end

    def varget(uri)
      obj = current_object
      raise MiqAeException::ObjectNotFound, "Current Object Not Found" if obj.nil?

      obj.uri2value(uri)
    end

    def varset(uri, value)
      scheme, _userinfo, _host, _port, _registry, path, _opaque, _query, fragment = MiqAeUri.split(uri)
      if scheme == "miqaews"
        o = get_obj_from_path(path)
        raise MiqAeException::ObjectNotFound, "Object Not Found for path=[#{path}]" if o.nil?

        o[fragment] = value
        return true
      end
      false
    end

    def instantiate(uri, user, root = nil)
      @ae_user = user
      @dom_search.ae_user = user
      scheme, _userinfo, _host, _port, _registry, path, _opaque, query, fragment = MiqAeUri.split(uri, "miqaedb")

      raise MiqAeException::InvalidPathFormat, "Unsupported Scheme [#{scheme}]" unless MiqAeUri.scheme_supported?(scheme)
      raise MiqAeException::InvalidPathFormat, "Invalid URI <#{uri}>" if path.nil?

      message = fragment.blank? ? "create" : fragment.downcase
      args = MiqAeUri.query2hash(query)
      miq_request_id = self.class.find_miq_request_id(args)

      $miq_ae_logger.info("Instantiating [#{ManageIQ::Password.sanitize_string(uri)}]", :resource_id => miq_request_id) if root.nil?

      if (ae_state_data = args.delete('ae_state_data'))
        @persist_state_hash.merge!(YAML.safe_load(ae_state_data, :permitted_classes => [MiqAeEngine::StateVarHash]))
      end

      if (ae_state_previous = args.delete('ae_state_previous'))
        load_previous_state_info(ae_state_previous)
      end

      ns, klass, instance = MiqAePath.split(path)
      ns = overlay_namespace(scheme, uri, ns, klass, instance)
      current = @current.last
      ns ||= current[:ns] if current
      klass ||= current[:klass] if current

      pushed = false
      is_state_machine = false
      raise MiqAeException::CyclicalRelationship, "cyclical reference: [#{MiqAeObject.fqname(ns, klass, instance)} with message=#{message}]" if cyclical?(ns, klass, instance, message)

      begin
        if scheme == "miqaedb"
          obj = MiqAeObject.new(self, ns, klass, instance)

          @current.push(:ns => ns, :klass => klass, :instance => instance, :object => obj, :message => message)
          pushed = true
          @nodes << obj
          link_parent_child(root, obj) if root

          if obj.state_machine?
            save_current_state_info(@state_machine_objects.last) unless @state_machine_objects.empty?
            @state_machine_objects.push(obj.object_name)
            reset_state_info(obj.object_name)
            is_state_machine = true
          end

          obj.process_assertions(message)
          obj.process_args_as_attributes(args)
          obj.user_info_attributes(@ae_user) unless root
        elsif scheme == "miqaews"
          obj = get_obj_from_path(path)
          raise MiqAeException::ObjectNotFound, "Object [#{path}] not found" if obj.nil?
        elsif ["miqaemethod", "method"].include?(scheme)
          raise MiqAeException::MethodNotFound, "No Current Object" if current[:object].nil?

          return current[:object].process_method_via_uri(uri)
        end
        obj.process_fields(message)
      rescue MiqAeException::MiqAeDatastoreError => err
        $miq_ae_logger.error(err.message, :resource_id => miq_request_id)
      rescue MiqAeException::AssertionFailure => err
        $miq_ae_logger.info(err.message, :resource_id => miq_request_id)
        delete(obj)
      rescue MiqAeException::StopInstantiation => err
        $miq_ae_logger.info("Stopping instantiation because [#{err.message}]", :resource_id => miq_request_id)
        delete(obj)
      rescue MiqAeException::UnknownMethodRc => err
        $miq_ae_logger.error("Aborting instantiation (unknown method return code) because [#{err.message}]", :resource_id => miq_request_id)
        raise
      rescue MiqAeException::AbortInstantiation => err
        $miq_ae_logger.info("Aborting instantiation because [#{err.message}]", :resource_id => miq_request_id)
        raise
      ensure
        @current.pop if pushed
        pop_state_machine_info if is_state_machine && self.root
      end

      obj
    end

    def pop_state_machine_info
      last_state_machine = @state_machine_objects.pop
      case root['ae_result']
      when 'ok'
        @current_state_info.delete(last_state_machine)
      when 'retry'
        save_current_state_info(last_state_machine)
      end
      reset_state_info(@state_machine_objects.last) unless @state_machine_objects.empty?
    end

    def to_expanded_xml(path = nil)
      objs = path.nil? ? roots : get_obj_from_path(path)
      objs = [objs] unless objs.kind_of?(Array)

      require 'builder'
      xml = Builder::XmlMarkup.new(:indent => 2)
      xml.MiqAeWorkspace do
        objs.each { |obj| obj.to_xml(:builder => xml) }
      end
    end

    def to_xml(path = nil)
      objs = path.nil? ? roots : get_obj_from_path(path)
      result = objs.collect { |obj| to_hash(obj) }.compact
      s = ""
      XmlHash.from_hash({"MiqAeObject" => result}, {:rootname => "MiqAeWorkspace"}).to_xml.write(s, 2)
      s
    end

    def to_dot(path = nil)
      require "rubygems"
      require "graphviz"

      objs = path.nil? ? roots : get_obj_from_path(path)

      g = GraphViz.new("MiqAeWorkspace", :type => "digraph", :output => "dot")
      objs.each { |obj| obj_to_dot(g, obj) }
      g.output(:output => "none")
    end

    def obj_to_dot(graph, obj)
      return nil if obj.nil?
      o = graph.add_node(obj.object_name)
      # o["MiqAeClass"]     = obj.klass
      # o["MiqAeNamespace"] = obj.namespace
      # o["MiqAeInstance"]  = obj.instance
      # obj.attributes
      obj.children.each do |child|
        c = obj_to_dot(graph, child)
        graph.add_edge(o, c) unless c.nil?
      end
      o
    end

    def to_hash(obj)
      result = {
        "namespace"   => obj.namespace,
        "class"       => obj.klass,
        "instance"    => obj.instance,
        "attributes"  => obj.attributes.delete_if { |_k, v| v.nil? }.inspect,
        "MiqAeObject" => obj.children.collect { |c| to_hash(c) }
      }
      result.delete_if { |_k, v| v.nil? }
    end

    def cyclical?(namespace, klass, instance, message)
      # check for cyclical references
      @current.each do |c|
        hash = {:ns => namespace, :klass => klass, :instance => instance, :message => message}
        return true if hash.all? do |key, value|
                         begin
                           value.casecmp(c[key]).zero?
                         rescue StandardError
                           false
                         end
                       end
      end
      false
    end

    def current_object
      current(:object)
    end

    def current_message
      current(:message)
    end

    def current_namespace
      current(:ns)
    end

    def current_class
      current(:klass)
    end

    def current_instance
      current(:instance)
    end

    def current(elem = nil)
      c = @current.last
      return c if elem.nil? || c.nil?

      c[elem]
    end

    def push_method(name)
      current = @current.last.dup
      current[:method] = name
      @current.push(current)
    end

    def pop_method
      @current.pop
    end

    def current_method
      current(:method)
    end

    def root(attrib = nil)
      return nil if roots.empty?
      return roots.first if attrib.nil?

      roots.first.attributes[attrib.downcase]
    end

    def roots
      @nodes.reject(&:node_parent)
    end

    def get_obj_from_path(path)
      obj = current_object

      return obj if path.nil? || path.blank?

      path = path[1..-1] if path[0, 2] == "/."

      if path == "/"
        return roots[0] if obj.nil?

        loop do
          parent = obj.node_parent
          return obj if parent.nil?

          obj = parent
        end
      elsif path[0, 1] == "."
        plist = path.split("/")
        until plist.empty?
          part = plist.shift
          next if part.blank? || part == "."
          raise MiqAeException::InvalidPathFormat, "bad part [#{part}] in path [#{path}]" if part != ".."

          obj = obj.node_parent
        end
      else
        obj = find_named_ancestor(path)
        # if not found try finding object in whole workspace
        obj ||= find_obj_entry(path)
      end
      obj
    end

    def find_named_ancestor(path)
      path = path[1..-1] if path[0] == '/'
      plist = path.split("/")
      raise MiqAeException::InvalidPathFormat, "Unsupported Path [#{path}]" if plist[0].blank?

      klass = plist.pop
      ns    = plist.length.zero? ? "*" : plist.join('/')

      obj = current_object
      while (obj = obj.node_parent)
        next unless klass.casecmp(obj.klass).zero?
        break if ns == "*"

        ns_split = obj.namespace.split('/')
        ns_split.shift # sans domain
        break if ns.casecmp(ns_split.join('/')).zero?
      end
      obj
    end

    def overlay_namespace(scheme, uri, namespace, klass, instance)
      @dom_search.get_alternate_domain(scheme, uri, namespace, klass, instance)
    end

    def overlay_method(namespace, klass, method)
      @dom_search.get_alternate_domain_method('miqaedb', "#{namespace}/#{klass}/#{method}", namespace, klass, method)
    end

    private

    def delete(id)
      @nodes.delete(id)
      id.children.each { |node| node.node_parent = nil }
    end

    def link_parent_child(parent, child)
      parent.node_children << child
      child.node_parent = parent
    end
  end
end
