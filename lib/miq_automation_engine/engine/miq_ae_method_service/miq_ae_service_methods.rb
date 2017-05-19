#####################################################
# This is for $evm.execute from an Automate method
#####################################################
module MiqAeMethodService
  class MiqAeServiceMethods
    include DRbUndumped

    SYNCHRONOUS = Rails.env.test?

    def self.send_email(to, from, subject, body, content_type = nil)
      ar_method do
        meth = SYNCHRONOUS ? :deliver : :deliver_queue
        options = {
          :to           => to,
          :from         => from,
          :subject      => subject,
          :content_type => content_type,
          :body         => body
        }
        GenericMailer.send(meth, :automation_notification, options)
        true
      end
    end

    def self.snmp_trap_v1(inputs)
      ar_method do
        if SYNCHRONOUS
          MiqSnmp.trap_v1(inputs)
        else
          MiqQueue.put(
            :class_name  => "MiqSnmp",
            :method_name => "trap_v1",
            :args        => [inputs],
            :role        => "notifier",
            :zone        => nil
          )
        end
        true
      end
    end

    def self.snmp_trap_v2(inputs)
      ar_method do
        if SYNCHRONOUS
          MiqSnmp.trap_v2(inputs)
        else
          MiqQueue.put(
            :class_name  => "MiqSnmp",
            :method_name => "trap_v2",
            :args        => [inputs],
            :role        => "notifier",
            :zone        => nil
          )
        end
        true
      end
    end

    def self.vm_templates
      ar_method do
        vms = VmOrTemplate.where(:template => true, :vendor => 'vmware').where.not(:ems_id => nil)
        MiqAeServiceModelBase.wrap_results(vms)
      end
    end

    def self.category_exists?(category)
      ar_method do
        Classification.find_by_name(category).present?
      end
    end

    def self.category_create(options = {})
      ar_method do
        ar_options = {}
        options.each { |k, v| ar_options[k.to_sym] = v if Classification.column_names.include?(k.to_s) || k.to_s == 'name' }
        cat = Classification.create_category!(ar_options)
        true
      end
    end

    def self.tag_exists?(category, entry)
      ar_method do
        cat = Classification.find_by_name(category)
        cat.present? && cat.find_entry_by_name(entry).present?
      end
    end

    def self.tag_create(category, options = {})
      ar_method do
        cat = Classification.find_by_name(category)
        raise "Category <#{category}> does not exist" if cat.nil?

        ar_options = {}
        options.each { |k, v| ar_options[k.to_sym] = v if Classification.column_names.include?(k.to_s) || k.to_s == 'name' }
        entry = cat.add_entry(ar_options)
        true
      end
    end

    def self.create_provision_request(*args)
      # Need to add the username into the array of params
      # TODO: This code should pass a real username, similar to how the web-service
      #      passes the name of the user that logged into the web-service.
      args.insert(1, User.find_by_userid("admin")) if args.kind_of?(Array)
      MiqAeServiceModelBase.wrap_results(MiqProvisionVirtWorkflow.from_ws(*args))
    end

    def self.create_automation_request(options, userid = "admin", auto_approve = false)
      user = User.find_by_userid!(userid)
      MiqAeServiceModelBase.wrap_results(AutomationRequest.create_request(options, user, auto_approve))
    end

    def self.drb_undumped(klass)
      _log.info "Entered: klass=#{klass.name}"
      klass.include(DRbUndumped) unless klass.ancestors.include?(DRbUndumped)
    end
    private_class_method :drb_undumped

    def self.ar_method
      yield
    rescue Exception => err
      $miq_ae_logger.error("MiqAeServiceMethods.ar_method raised: <#{err.class}>: <#{err.message}>")
      $miq_ae_logger.error(err.backtrace.join("\n"))
      raise
    ensure
      ActiveRecord::Base.connection_pool.release_connection rescue nil
    end
    private_class_method :ar_method
  end
end
