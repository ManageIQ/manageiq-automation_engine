module MiqAeEvent
  def self.raise_ems_event(event)
    aevent = {
      :event_id        => event.id,
      :event_stream_id => event.id,
      :event_type      => event.event_type,
    }

    if event.source == 'VC'
      unless event.ext_management_system.nil?
        aevent['ExtManagementSystem::ems'] = event.ext_management_system.id
        aevent[:ems_id] = event.ext_management_system.id
      end
    end

    unless event.src_vm_or_template.nil?
      aevent['VmOrTemplate::vm'] = event.src_vm_or_template.id
      aevent[:vm_id] = event.src_vm_or_template.id
    end
    unless event.dest_vm_or_template.nil?
      aevent['VmOrTemplate::dest_vm'] = event.dest_vm_or_template.id
      aevent[:dest_vm_id] = event.dest_vm_or_template.id
    end
    unless event.src_host.nil?
      aevent['Host::host'] = event.src_host.id
      aevent[:host_id] = event.src_host.id
    end
    unless event.dest_host.nil?
      aevent['Host::dest_host'] = event.dest_host.id
      aevent[:dest_host_id] = event.dest_host.id
    end

    call_automate(event, aevent, 'Event')
  end

  def self.raise_synthetic_event(target, event, inputs, options = {})
    if event == 'vm_retired'
      instance    = 'Automation'
      aevent      = {'request' => event}
    else
      instance    = 'Event'
      aevent      = build_evm_event(event, inputs)
    end

    call_automate(target, aevent, instance, options)
  end

  def self.raise_evm_event(event_name, target, inputs = {}, options = {})
    if target.kind_of?(Array)
      klass, id = target
      target = ApplicationRecord.const_get(klass).find(id)
    end

    call_automate(target, build_evm_event(event_name, inputs), 'Event', options)
  end

  def self.eval_alert_expression(target, inputs, options = {})
    aevent = build_evm_event('alert', inputs)
    aevent[:request] = 'evaluate'
    aevent.merge!(inputs)
    ws = call_automate(target, aevent, 'Alert', options)
    return nil if ws.nil? || ws.root.nil?

    ws.root['ae_result']
  end

  def self.build_evm_event(event, passed_inputs = {})
    inputs = passed_inputs.dup

    # TODO: Add to Request Logs
    $miq_ae_logger.info("MiqAeEvent.build_evm_event >> event=<#{event.inspect}> inputs=<#{inputs.inspect}>")
    event_type = event.respond_to?(:name) ? event.name : event
    aevent = {:event_type => event_type}

    [
      {:key => :vm,     :name => 'vm',         :class => VmOrTemplate},
      {:key => :ems,    :name => 'ems',        :class => ExtManagementSystem},
      {:key => :host,   :name => 'host',       :class => Host},
      {:key => :policy, :name => 'miq_policy', :class => MiqPolicy}
    ].each do |hash|
      next if inputs[hash[:key]].nil?

      if inputs[hash[:key]].kind_of?(Hash)
        input = inputs.delete(hash[:key])
        raise "Unexpected class #{input[:vmdb_class]} for #{hash[:key]} -- expected class=#{hash[:class].name}" if input[:vmdb_class] != hash[:class].name
        raise "Invalid vmdb_id=#{input[:vmdb_id].inspect} for #{hash[:key]}" unless input[:vmdb_id].kind_of?(Numeric)

        vmdb_object = hash[:class].find_by(:id => input[:vmdb_id])
        raise "VMDB Object not found" if vmdb_object.nil?
      elsif inputs[hash[:key]].kind_of?(hash[:class])
        vmdb_object = inputs.delete(hash[:key])
      else
        raise "Unexpected class #{inputs[hash[:key]].class.name} for #{hash[:key]} -- expected class=#{hash[:class].name}"
      end

      aevent.merge!("#{hash[:class].name}::#{hash[:name]}" => vmdb_object.id, "#{hash[:key]}_id".to_sym => vmdb_object.id)
    end

    inputs.delete_if do |_k, value|
      next unless value.kind_of?(ApplicationRecord)

      klass = value.class.base_class.name
      aevent.merge!("#{klass}::#{klass.underscore}" => value.id, "#{klass.underscore}_id".to_sym => value.id)
    end

    aevent.merge(inputs)
  end

  def self.process_result(ae_result, aevent)
    scheme, _userinfo, _host, _port, _registry, _path, _opaque, query, _fragment = MiqAeEngine::MiqAeUri.split(ae_result)
    args = MiqAeEngine::MiqAeUri.query2hash(query)

    if scheme.casecmp('miqpeca').zero?
      # Pass to policy
      #   Sample URI: 'miqpeca:///event?logical_event=vm_retire_warn'
      # inputs were either passed through EVM eveny (aka policy event) of fabricated (below) from an EMS event
      inputs = aevent.delete(:inputs)

      # TODO: Need to setup inputs for policy.
      unless inputs
        inputs = {}
        inputs[:vm]                    = Vm.find_by(:id => aevent[:vm_id])                   unless aevent[:vm_id].nil?
        inputs[:host]                  = Host.find_by(:id => aevent[:host_id])               unless aevent[:host_id].nil?
        inputs[:ext_management_system] = ExtManagementSystem.find_by(:id => aevent[:ems_id]) unless aevent[:ems_id].nil?
      end
      target     = inputs.delete(:target) || inputs['vm']
      event_name = args['logical_event'] || aevent[:event_type]
      $miq_ae_logger.info("Enforcing Policy [#{ae_result}]")
      MiqPolicy.enforce_policy(target, event_name, inputs) unless target.nil?
    end
  rescue URI::InvalidURIError => err
    $miq_ae_logger.error(err.message)
  end

  def self.call_automate(obj, attrs, instance_name, options = {})
    user = User.current_user || obj.tenant_identity
    raise "A user is needed to raise #{instance_name} to automate. [#{obj.class.name}] id:[#{obj.id}]" unless user

    q_options = {
      :miq_callback => options[:miq_callback],
      :priority     => MiqQueue::HIGH_PRIORITY,
      :user_id      => user.id,
      :group_id     => user.current_group.id,
      :tenant_id    => user.current_tenant.id,
      :task_id      => nil # Clear task_id to allow running synchronously under current worker process
    }
    q_options[:zone] = options[:zone] if options[:zone].present?

    args = {
      :object_type      => obj.class.name,
      :object_id        => obj.id,
      :attrs            => attrs,
      :instance_name    => instance_name,
      :user_id          => user.id,
      :miq_group_id     => user.current_group.id,
      :tenant_id        => user.current_tenant.id,
      :automate_message => options[:message]
    }

    sync = options[:synchronous]
    if sync
      MiqAeEngine.deliver(args)
    else
      MiqAeEngine.deliver_queue(args, q_options)
    end
  end
  private_class_method :call_automate
end
