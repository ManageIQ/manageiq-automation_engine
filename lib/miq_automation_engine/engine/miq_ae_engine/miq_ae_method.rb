module MiqAeEngine
  class MiqAeMethod
    def self.ae_methods_dir
      @ae_methods_dir ||= begin
        Rails.root.join("product", "automate", "methods").tap { |path| Dir.mkdir_p(path) unless path.directory? }
      end
    end

    def self.invoke_inline(aem, obj, inputs)
      return invoke_inline_ruby(aem, obj, inputs) if aem.language.downcase.strip == "ruby"

      raise  MiqAeException::InvalidMethod, "Inline Method Language [#{aem.language}] not supported"
    end

    def self.invoke_expression(aem, obj, inputs)
      MiqAeEngine::MiqAeExpressionMethod.new(aem, obj, inputs).run
    end

    def self.invoke_playbook(aem, obj, inputs)
      MiqAeEngine::MiqAePlaybookMethod.new(aem, obj, inputs).run
    end

    def self.invoke_ansible_job_template(aem, obj, inputs)
      MiqAeEngine::MiqAeAnsibleTemplateMethod.new(aem, obj, inputs).run
    end

    def self.invoke_ansible_workflow_template(aem, obj, inputs)
      MiqAeEngine::MiqAeAnsibleTemplateMethod.new(aem, obj, inputs).run
    end

    def self.invoke_uri(aem, obj, _inputs)
      uri = URI.parse(aem.data)

      unless uri.scheme.casecmp?("file")
        msg = "Specified URI [#{aem.data}] in Method [#{aem.name}] has unsupported scheme of #{scheme}; supported scheme is file"
        raise MiqAeException::MethodNotFound, msg
      end

      if uri.path.blank?
        raise  MiqAeException::MethodNotFound, "Invalid file specification -- #{aem.data}"
      end

      # Create the filename corresponding to the URI specification
      fname = ae_methods_dir.join(uri.path)
      raise MiqAeException::MethodNotFound, "Method [#{aem.data}] Not Found (fname=#{fname})" unless File.exist?(fname)

      cmd = "#{aem.language} #{fname}"
      invoke_external(cmd, obj.workspace)
    end

    def self.invoke_builtin(aem, obj, inputs)
      mname = "miq_#{aem.data.blank? ? aem.name.downcase : aem.data.downcase}"
      raise MiqAeException::MethodNotFound, "Built-In Method [#{mname}] does not exist" unless MiqAeBuiltinMethod.public_methods.collect(&:to_s).include?(mname)

      # Create service, since built-in method may be calling things that assume there is one
      svc = MiqAeMethodService::MiqAeService.new(obj.workspace)

      begin
        return MiqAeBuiltinMethod.send(mname, obj, inputs)
      rescue StandardError => err
        raise MiqAeException::AbortInstantiation, err.message
      ensure
        # Destroy service to avoid storing object references
        svc.destroy
      end
    end

    def self.invoke(obj, aem, args)
      inputs = {}
      miq_request_id = obj.workspace.find_miq_request_id

      aem.inputs.each do |f|
        key   = f.name
        value = args[key]
        value = obj.attributes[key] || obj.get_value(f) if value.nil?
        inputs[key] = MiqAeObject.convert_value_based_on_datatype(value, f["datatype"])

        if obj.attributes[key] && f["datatype"] != "string"
          # the attributes data in the object start as string
          # if the datatype of the value stored in the object should be converted,
          # then update the object with the converted value
          obj.attributes[key] = MiqAeObject.convert_value_based_on_datatype(obj.attributes[key], f["datatype"])
        end

        raise MiqAeException::MethodParmMissing, "Method [#{aem.fqname}] requires parameter [#{f.name}]" if inputs[key].nil?
      end

      if obj.workspace.readonly?
        $miq_ae_logger.info("Workspace Instantiation is READONLY -- skipping method [#{aem.fqname}] with inputs [#{inputs.inspect}]", :resource_id => miq_request_id)
      elsif %w[inline builtin uri expression playbook ansible_job_template ansible_workflow_template].include?(aem.location.downcase.strip)
        $miq_ae_logger.info("Invoking [#{aem.location}] method [#{aem.fqname}] with inputs [#{inputs.inspect}]", :resource_id => miq_request_id)
        return MiqAeEngine::MiqAeMethod.send("invoke_#{aem.location.downcase.strip}", aem, obj, inputs)
      end

      nil
    end

    def self.invoke_external(cmd, workspace, serialize_workspace = false)
      ws = nil
      miq_request_id = workspace.find_miq_request_id

      if serialize_workspace
        ws, = Benchmark.realtime_block(:method_invoke_external_ws_create_time) { MiqAeWorkspace.create(:workspace => workspace) }
        $miq_ae_logger.debug("Invoking External Method with MIQ_TOKEN=#{ws.guid} and command=#{cmd}", :resource_id => miq_request_id)
      end

      # Release connection to thread that will be used by method process. It will return it when it is done
      ActiveRecord::Base.connection_pool.release_connection

      # Spawn separate Ruby process to run method

      ENV['MIQ_TOKEN'] = ws.guid unless ws.nil?

      rc, msg = run_method(*cmd, miq_request_id)
      if ws
        ws.reload
        ws.setters&.each { |uri, value| workspace.varset(uri, value) }
        ws.delete
      end
      process_ruby_method_results(rc, msg, miq_request_id)
    end
    private_class_method :invoke_external

    MIQ_OK    = 0
    MIQ_WARN  = 4
    MIQ_STOP  = 8
    MIQ_ABORT = 16

    def self.open_transactions_threshold
      @open_transactions_threshold ||= Rails.env.test? ? 1 : 0
    end
    private_class_method :open_transactions_threshold

    def self.verbose_rc(return_code)
      case return_code
      when MIQ_OK    then 'MIQ_OK'
      when MIQ_WARN  then 'MIQ_WARN'
      when MIQ_STOP  then 'MIQ_STOP'
      when MIQ_ABORT then 'MIQ_ABORT'
      else                "Unknown RC: [#{return_code}]"
      end
    end
    private_class_method :verbose_rc

    def self.run_ruby_method(code, miq_request_id)
      ActiveRecord::Base.connection_pool.release_connection unless Rails.env.test?
      with_automation_env do
        run_method(Gem.ruby, miq_request_id) do |stdin|
          stdin.puts(code)
        end
      end
    end
    private_class_method :run_ruby_method

    def self.with_automation_env
      gem_paths = (Gem.path + [Bundler.bundle_path.to_s]).uniq
      Bundler.with_unbundled_env do
        begin
          backup = ENV.to_hash
          ENV.replace(backup.merge("GEM_PATH" => gem_paths.join(File::PATH_SEPARATOR)))

          yield
        ensure
          ENV.replace(backup)
        end
      end
    end
    private_class_method :with_automation_env

    def self.process_ruby_method_results(return_code, msg, miq_request_id)
      case return_code
      when MIQ_OK
        $miq_ae_logger.info(msg, :resource_id => miq_request_id)
      when MIQ_WARN
        $miq_ae_logger.warn(msg, :resource_id => miq_request_id)
      when MIQ_STOP
        raise MiqAeException::StopInstantiation,  msg
      when MIQ_ABORT
        raise MiqAeException::AbortInstantiation, msg
      else
        raise MiqAeException::UnknownMethodRc, msg
      end
      return_code
    end
    private_class_method :process_ruby_method_results

    def self.ruby_method_runnable?(aem)
      return false if aem.data.blank?

      raise MiqAeException::Error, "Unable to launch Automate Method because currently in SQL transaction" if ActiveRecord::Base.connection.open_transactions > open_transactions_threshold

      true
    end
    private_class_method :ruby_method_runnable?

    def self.invoke_inline_ruby(aem, obj, inputs)
      miq_request_id = obj.workspace.find_miq_request_id
      if ruby_method_runnable?(aem)
        obj.workspace.invoker ||= MiqAeEngine::DrbRemoteInvoker.new(obj.workspace)
        bodies, script_info = bodies_and_line_numbers(obj, aem)
        obj.workspace.invoker.with_server(inputs, bodies, aem.fqname, script_info) do |code|
          $miq_ae_logger.info("<AEMethod [#{aem.fqname}]> Starting ", :resource_id => miq_request_id)
          rc, msg = run_ruby_method(code, miq_request_id)
          $miq_ae_logger.info("<AEMethod [#{aem.fqname}]> Ending", :resource_id => miq_request_id)
          process_ruby_method_results(rc, msg, miq_request_id)
        end
      end
    end
    private_class_method :invoke_inline_ruby

    def self.run_method(cmd, miq_request_id)
      require 'open3'
      rc = nil
      threads = []
      method_pid = nil
      begin
        status = Open3.popen3(*cmd) do |stdin, stdout, stderr, wait_thread|
          method_pid = wait_thread.pid
          yield stdin if block_given?
          stdin.close
          threads << Thread.new do
            stdout.each_line do |msg|
              $miq_ae_logger.info("Method STDOUT: #{msg.strip}", :resource_id => miq_request_id)
            end
          end
          threads << Thread.new do
            stderr.each_line do |msg|
              $miq_ae_logger.error("Method STDERR: #{msg.strip}", :resource_id => miq_request_id)
            end
          end
          threads.each(&:join)
          wait_thread.value
        end
        rc = status.exitstatus
        msg = "Method exited with rc=#{verbose_rc(rc)}"
        method_pid = nil
        threads = []
      rescue StandardError => err
        STDERR.puts "** AUTOMATE ** Method exec failed because #{err.class}:#{err.message}" if ENV.key?("CI") # rubocop:disable Style/StderrPuts
        $miq_ae_logger.error("Method exec failed because (#{err.class}:#{err.message})", :resource_id => miq_request_id)
        rc = MIQ_ABORT
        msg = "Method execution failed"
      ensure
        cleanup(method_pid, threads, miq_request_id)
      end
      return rc, msg
    end
    private_class_method :run_method

    def self.cleanup(method_pid, threads, miq_request_id)
      if method_pid
        begin
          $miq_ae_logger.error("Terminating non responsive method with pid #{method_pid.inspect}", :resource_id => miq_request_id)
          Process.kill("TERM", method_pid)
          Process.wait(method_pid)
        rescue Errno::ESRCH, RangeError => err
          $miq_ae_logger.error("Error terminating #{method_pid.inspect} exception #{err}", :resource_id => miq_request_id)
        end
      end
      threads.each(&:exit)
    end
    private_class_method :cleanup

    def self.bodies_and_line_numbers(obj, aem)
      embeds = []
      embedded_methods(obj.workspace, aem, embeds, aem.fqname)
      embeds << {:data => aem.data, :fqname => aem.fqname}
      code_start = 0
      script_info = {}
      bodies = []
      embeds.each do |item|
        bodies << item[:data]
        line_count = item[:data].lines.count
        code_end   = code_start + line_count
        script_info[item[:fqname]] = Range.new(code_start, code_end)
        code_start = code_end + 1
      end
      return bodies, script_info
    end
    private_class_method :bodies_and_line_numbers

    def self.embedded_methods(workspace, method_obj, current_items, top)
      miq_request_id = workspace.find_miq_request_id
      method_obj.embedded_methods.each do |name|
        method_name, klass, ns = embedded_method_name(name)
        match_ns = workspace.overlay_method(ns, klass, method_name)
        cls = ::MiqAeClass.lookup_by_fqname("#{match_ns}/#{klass}")
        aem = ::MiqAeMethod.find_by(:class_id => cls.id, :name => method_name) if cls
        raise MiqAeException::MethodNotFound, "Embedded method #{name} not found" unless aem

        fqname = "/#{match_ns}/#{klass}/#{method_name}"
        if top == fqname
          $miq_ae_logger.info("Skipping #{fqname}, cannot reference the top method", :resource_id => miq_request_id)
        elsif loaded?(current_items, fqname)
          $miq_ae_logger.info("Already loaded embedded method #{fqname}", :resource_id => miq_request_id)
        else
          current_items << {:data => aem.data, :fqname => fqname}
          $miq_ae_logger.info("Loading embedded method #{fqname}", :resource_id => miq_request_id)
          # Get the embedded methods for the this method
          embedded_methods(workspace, aem, current_items, top)
        end
      end
    end
    private_class_method :embedded_methods

    def self.embedded_method_name(fqname)
      parts = MiqAeUri.path(fqname).split('/')
      parts.shift # Remove the leading blank piece
      return parts.pop, parts.pop, parts.join('/')
    end
    private_class_method :embedded_method_name

    def self.loaded?(current_items, fqname)
      current_items.any? { |item| item[:fqname].casecmp(fqname).zero? }
    end
  end
end
