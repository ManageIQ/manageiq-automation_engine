#####################################################
# This is for $evm.execute from an Automate method
#####################################################
module MiqAeMethodService
  class MiqAeServiceMethods
    include DRbUndumped

    SYNCHRONOUS = Rails.env.test?

    def self.send_email(to, from, subject, body, *args, **kwargs)
      # TODO: Remove this mess once we're on ruby 3.0+ only: go back to only kwargs.
      # This is the only method that was expecting kwargs and one caller, execute_with_user,
      # was changed to capture the kwargs as a hash (via **kwargs) and append them to the args
      # and call MiqAeServiceMethods methods with those args. We now accept options hash as the last
      # args or kwargs for any non execute_with_user callers.
      options = if kwargs.present?
        kwargs
      else
        args.last || {}
      end

      # we accept only 3 kwargs / options keys
      options = options.slice(:cc, :bcc, :content_type)

      ar_method do
        meth = SYNCHRONOUS ? :deliver : :deliver_queue
        options.merge!({
          :to           => to,
          :from         => from,
          :subject      => subject,
          :body         => body
        })
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
        Classification.lookup_by_name(category).present?
      end
    end

    def self.category_create(options = {})
      ar_method do
        ar_options = {}
        options.each { |k, v| ar_options[k.to_sym] = v if Classification.column_names.include?(k.to_s) || k.to_s == 'name' }
        Classification.create_category!(ar_options)
        true
      end
    end

    def self.category_delete!(category)
      ar_method do
        cat = Classification.lookup_by_name(category)
        raise "Category <#{category}> does not exist" if cat.nil?

        if cat.entries.any? { |ent| AssignmentMixin.all_assignments(ent.tag.name).present? }
          raise "This category contains tags which have been assigned. Please delete assignments before deleting the category."
        end

        cat.destroy!
      end
    end

    def self.category_delete(category)
      category_delete!(category)
      true
    rescue StandardError
      false
    end

    def self.tag_exists?(category, entry)
      ar_method do
        cat = Classification.lookup_by_name(category)
        cat.present? && cat.find_entry_by_name(entry).present?
      end
    end

    def self.tag_create(category, options = {})
      ar_method do
        cat = Classification.lookup_by_name(category)
        raise "Category <#{category}> does not exist" if cat.nil?

        ar_options = {}
        options.each { |k, v| ar_options[k.to_sym] = v if Classification.column_names.include?(k.to_s) || k.to_s == 'name' }
        cat.add_entry(ar_options)
        true
      end
    end

    def self.tag_delete!(category, entry)
      ar_method do
        cat = Classification.lookup_by_name(category)
        raise "Category <#{category}> does not exist" if cat.nil?

        ent = cat.find_entry_by_name(entry)
        raise "Entry <#{entry}> does not exist" if ent.nil?

        raise "This tag has assignments. Please delete assignments before deleting the tag." if AssignmentMixin.all_assignments(ent.tag.name).present?

        ent.destroy!
      end
    end

    def self.tag_delete(category, entry)
      tag_delete!(category, entry)
      true
    rescue StandardError
      false
    end

    def self.create_provision_request(*args)
      # Need to add the username into the array of params
      # TODO: This code should pass a real username, similar to how the web-service
      #      passes the name of the user that logged into the web-service.
      args << User.lookup_by_userid("admin")
      MiqAeServiceModelBase.wrap_results(MiqProvisionVirtWorkflow.from_ws(*args))
    end

    def self.create_automation_request(options, userid = "admin", auto_approve = false)
      user = User.lookup_by_userid!(userid)
      MiqAeServiceModelBase.wrap_results(AutomationRequest.create_request(options, user, auto_approve))
    end

    def self.create_service_provision_request(svc_template, options = nil)
      result = svc_template.object_send(:provision_request, User.current_user, options)
      MiqAeServiceModelBase.wrap_results(result)
    end

    def self.create_retire_request(obj)
      obj_class = obj.object_class.base_model.name.constantize
      MiqAeServiceModelBase.wrap_results(obj_class.make_retire_request(obj.id, User.current_user))
    end

    def self.drb_undumped(klass)
      _log.info("Entered: klass=#{klass.name}")
      klass.include(DRbUndumped) unless klass.ancestors.include?(DRbUndumped)
    end
    private_class_method :drb_undumped

    def self.ar_method
      yield
    rescue Exception => err # rubocop:disable Lint/RescueException
      $miq_ae_logger.error("MiqAeServiceMethods.ar_method raised: <#{err.class}>: <#{err.message}>")
      $miq_ae_logger.error(err.backtrace.join("\n"))
      raise
    ensure
      begin
        ActiveRecord::Base.connection_pool.release_connection
      rescue StandardError
        nil
      end
    end
    private_class_method :ar_method
  end
end
