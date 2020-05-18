describe "MultipleStateMachineSteps" do
  include Spec::Support::AutomationHelper

  before do
    Tenant.seed
    MiqAeDatastore.reset_default_namespace
    @instance1           = 'instance1'
    @instance2           = 'instance2'
    @instance3           = 'instance3'
    @method_class        = 'MY_METHOD_CLASS'
    @common_method_name  = 'standard'
    @common_state_method = 'common_state_method'
    @domain              = 'SPEC_DOMAIN'
    @namespace           = 'NS1'
    @max_retries         = 2
    @state_class1        = 'SM1'
    @state_class2        = 'SM2'
    @state_class3        = 'SM3'
    @state_instance      = 'MY_STATE_INSTANCE'
    @fqname              = '/SPEC_DOMAIN/NS1/SM1/MY_STATE_INSTANCE'
    @miq_server = FactoryBot.create(:miq_server)
    @user = FactoryBot.create(:user_with_group)
    @method_params = {'ae_result'     => {:datatype => 'string', 'default_value' => 'ok'},
                      'ae_next_state' => {:datatype => 'string'},
                      'raise'         => {:datatype => 'string'}}
    @automate_args = {:namespace        => "#{@domain}/#{@namespace}",
                      :class_name       => @state_class1,
                      :instance_name    => @state_instance,
                      :user_id          => @user.id,
                      :miq_group_id     => @user.current_group_id,
                      :tenant_id        => @user.current_tenant.id,
                      :automate_message => 'create'}
    zone = FactoryBot.create(:zone)
    allow(MiqServer).to receive(:my_zone).and_return(zone.name)
    allow(MiqServer).to receive(:my_server).and_return(@miq_server)
    clear_domain
    setup_model
  end

  def clear_domain
    MiqAeDomain.find_by_name(@domain).try(:destroy)
  end

  def common_method_script
    <<-'RUBY'
      $evm.log(:info, "Method starting #{$evm.inputs.inspect}")
      inputs = $evm.inputs
      states_executed = $evm.root['states_executed'].to_a
      states_executed << $evm.root['ae_state']
      $evm.root['states_executed'] = states_executed
      $evm.root['ae_result'] = inputs['ae_result']
      $evm.root['ae_next_state']  = inputs['ae_next_state'] unless inputs['ae_next_state'].blank?
      raise inputs['raise'] unless inputs['raise'].blank?
    RUBY
  end

  def common_state_method_script
    <<-'RUBY'
      $evm.log(:info, "State Method starting #{$evm.inputs.inspect}")
      inputs = $evm.inputs
      step_name = "step_#{$evm.root['ae_state_step']}"
      steps_executed = $evm.root[step_name].to_a
      steps_executed << $evm.root['ae_state']
      $evm.root[step_name] = steps_executed
      max_retries = $evm.root['ae_state'].split('_').last.to_i
      $evm.root['ae_result'] = 'error' unless $evm.root['ae_state_max_retries'] == max_retries
      $evm.root['ae_result'] = inputs['ae_result'] if %w(retry error).exclude?($evm.root['ae_result'])
      $evm.root['ae_result'] = inputs['ae_result'] if inputs['ae_result'] == 'continue'
      $evm.root['ae_next_state']  = inputs['ae_next_state'] unless inputs['ae_next_state'].blank?
      raise inputs['raise'] unless inputs['raise'].blank?
    RUBY
  end

  def setup_model
    dom = FactoryBot.create(:miq_ae_domain, :enabled => true, :name => @domain)
    ns  = FactoryBot.create(:miq_ae_namespace, :parent_id => dom.id, :name => @namespace)
    @ns_fqname = ns.fqname
    create_method_class(:namespace => @ns_fqname, :name => @method_class)
    connect = "/#{@domain}/#{@namespace}/#{@state_class2}/#{@state_instance}"
    create_state_class(:namespace => @ns_fqname, :name => @state_class1, :connect => connect)
    connect = "/#{@domain}/#{@namespace}/#{@state_class3}/#{@state_instance}"
    create_state_class(:namespace => @ns_fqname, :name => @state_class2, :connect => connect)
    create_state_class(:namespace => @ns_fqname, :name => @state_class3, :connect => "#")
  end

  def create_method_class(attrs = {})
    ae_fields = {'ae_result'     => {:aetype => 'attribute', :datatype => 'string',
                                     :default_value => "ok", :priority => 1},
                 'ae_next_state' => {:aetype => 'attribute', :datatype => 'string',
                                     :priority => 2},
                 'raise'         => {:aetype => 'attribute', :datatype => 'string',
                                     :priority => 3},
                 'execute'       => {:aetype => 'method',    :datatype => 'string',
                                     :priority => 4}}
    inst_values = {'execute'       => {:value => @common_method_name},
                   'ae_result'     => {:value => 'ok'},
                   'ae_next_state' => {:value => ""},
                   'raise'         => {:value => ""}}
    ae_instances = {@instance1 => inst_values, @instance2 => inst_values,
                    @instance3 => inst_values}
    ae_methods = {@common_method_name => {:scope => 'instance', :location => 'inline',
                                           :data => common_method_script,
                                           :language => 'ruby', :params => @method_params}}

    FactoryBot.create(:miq_ae_class, :with_instances_and_methods,
                      attrs.merge('ae_fields'    => ae_fields,
                                  'ae_instances' => ae_instances,
                                  'ae_methods'   => ae_methods))
  end

  def create_state_class(attrs = {})
    connect = attrs.delete(:connect)
    stem    = attrs[:name]
    all_steps = {'on_entry' => "common_state_method",
                 'on_exit'  => "common_state_method",
                 'on_error' => "common_state_method"}
    ae_fields = {"#{stem}_1" => {:aetype => 'state', :datatype => 'string', :priority => 1, :max_retries => 1},
                 "#{stem}_2" => {:aetype => 'state', :datatype => 'string', :priority => 2,
                                 :max_retries => @max_retries, :message => 'create'},
                 "#{stem}_3" => {:aetype => 'state', :datatype => 'string', :priority => 3, :max_retries => 3},
                 "#{stem}_4" => {:aetype => 'state', :datatype => 'string', :priority => 4, :max_retries => 4}}
    state1_value = "/#{@domain}/#{@namespace}/#{@method_class}/#{@instance1}"
    state2_value = "/#{@domain}/#{@namespace}/#{@method_class}/#{@instance2}"
    state3_value = "/#{@domain}/#{@namespace}/#{@method_class}/#{@instance3}"
    ae_instances = {@state_instance => {"#{stem}_1" => {:value => state1_value}.merge(all_steps),
                                        "#{stem}_2" => {:value => connect}.merge(all_steps),
                                        "#{stem}_3" => {:value => state2_value}.merge(all_steps),
                                        "#{stem}_4" => {:value => state3_value}.merge(all_steps)}}

    FactoryBot.create(:miq_ae_class, :with_instances_and_methods,
                      attrs.merge('ae_fields'    => ae_fields,
                                  'ae_methods'   => state_methods,
                                  'ae_instances' => ae_instances))
  end

  def state_methods
    {@common_state_method => {:scope => 'instance', :location => 'inline',
                              :data => common_state_method_script,
                              :language => 'ruby', 'params' => @method_params}}
  end

  def tweak_instance(class_fqname, instance, field_name, attribute, value)
    klass = MiqAeClass.lookup_by_fqname(class_fqname)
    field = klass.ae_fields.detect { |f| f.name == field_name }
    ins   = klass.ae_instances.detect { |inst| inst.name == instance }
    update_value(ins, field, attribute, value)
  end

  def update_value(instance, field, attribute, value)
    ins_v = instance.ae_values.detect { |v| v.field_id == field.id }
    ins_v[attribute] = value
    ins_v.save
    instance.save
  end

  it "process all states" do
    all_states = %w[SM1_1 SM1_3 SM1_4 SM2_1 SM2_3 SM2_4 SM3_1 SM3_3 SM3_4]
    guard_states = all_states + %w[SM1_2 SM2_2 SM3_2]
    send_ae_request_via_queue(@automate_args)
    _status, _message, ws = deliver_ae_request_from_queue

    expect(ws.root.attributes['states_executed']).to match_array(all_states)
    expect(ws.root.attributes['step_on_entry']).to match_array(guard_states)
    expect(ws.root.attributes['step_on_exit']).to match_array(guard_states)
    expect(ws.root.attributes['step_on_error']).to be_nil
  end

  it "one of the lower state machine raises an exception" do
    # The on_error method will get executed in the bottom most state
    # machine and as well as all the states from the parents that
    # connect to the child state machine.
    tweak_instance("/#{@domain}/#{@namespace}/#{@state_class3}", @state_instance,
                   'SM3_1', 'on_entry',
                   "common_state_method(raise => 'Raising error from SM3')")
    tweak_instance("/#{@domain}/#{@namespace}/#{@state_class3}", @state_instance,
                   'SM3_1', 'on_error',
                   "common_state_method(ae_result => 'error')")
    send_ae_request_via_queue(@automate_args)
    _status, _message, ws = deliver_ae_request_from_queue

    all_states = %w[SM1_1 SM2_1]
    on_entry_states = %w[SM1_1 SM1_2 SM2_1 SM2_2 SM3_1]
    expect(ws.root.attributes['states_executed']).to match_array(all_states)
    expect(ws.root.attributes['step_on_exit']).to match_array(all_states)
    expect(ws.root.attributes['step_on_error']).to match_array(%w[SM3_1 SM2_2 SM1_2])
    expect(ws.root.attributes['step_on_entry']).to match_array(on_entry_states)
  end

  it "one of the lower state machine raises an exception but continues" do
    # The on_error method will get executed in the bottom most state
    # machine which will reset it to continue
    tweak_instance("/#{@domain}/#{@namespace}/#{@state_class3}", @state_instance,
                   'SM3_1', 'on_entry',
                   "common_state_method(raise => 'Raising error from SM3')")
    tweak_instance("/#{@domain}/#{@namespace}/#{@state_class3}", @state_instance,
                   'SM3_1', 'on_error',
                   "common_state_method(ae_result => 'continue')")
    send_ae_request_via_queue(@automate_args)
    _status, _message, ws = deliver_ae_request_from_queue

    all_states = %w[SM1_1 SM1_3 SM1_4 SM2_1 SM2_3 SM2_4 SM3_3 SM3_4]
    guard_states = all_states + %w[SM1_2 SM2_2 SM3_1 SM3_2]

    expect(ws.root.attributes['states_executed']).to match_array(all_states)
    expect(ws.root.attributes['step_on_entry']).to match_array(guard_states)
    expect(ws.root.attributes['step_on_exit']).to match_array(guard_states - %w[SM3_1])
    expect(ws.root.attributes['step_on_error']).to match_array(%w[SM3_1])
  end

  it "one of the lower state machine causes a retry" do
    # The on_error method will get executed in the bottom most state
    # machine and as well as all the states from the parents that
    # connect to the child state machine.
    tweak_instance("/#{@domain}/#{@namespace}/#{@state_class3}", @state_instance,
                   'SM3_1', 'on_entry',
                   "common_state_method(ae_result => 'retry')")
    send_ae_request_via_queue(@automate_args)
    _status, _message, ws = deliver_ae_request_from_queue
    all_states = %w[SM1_1 SM2_1]
    expect(ws.root.attributes['states_executed']).to match_array(all_states)
    expect(ws.root.attributes['step_on_entry']).to match_array(all_states + %w[SM1_2 SM2_2 SM3_1])
    (@max_retries).times do
      status, _message, ws = deliver_ae_request_from_queue
      expect(status).not_to eq(MiqQueue::STATUS_ERROR)
      expect(ws).not_to be_nil
      expect(ws.root.attributes['step_on_entry']).to match_array(%w[SM1_2 SM2_2 SM3_1])
    end

    status, _message, ws = deliver_ae_request_from_queue
    expect(status).not_to eq(MiqQueue::STATUS_ERROR)
    expect(ws).not_to be_nil
    expect(ws.root.attributes['step_on_entry']).to match_array(%w[SM1_2])

    expect(deliver_ae_request_from_queue).to be_nil
  end
end
