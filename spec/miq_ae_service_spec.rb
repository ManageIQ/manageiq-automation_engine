describe MiqAeMethodService::MiqAeServiceObject do
  before do
    @object = double('object')
    @service = double('service')
    @service_object = described_class.new(@object, @service)
  end

  context "#attributes" do
    before do
      allow(@object).to receive(:attributes).and_return('true'     => true,
                                           'false'    => false,
                                           'time'     => Time.parse('Aug 30, 2013'),
                                           'symbol'   => :symbol,
                                           'int'      => 1,
                                           'float'    => 1.1,
                                           'string'   => 'hello',
                                           'array'    => [1, 2, 3, 4],
                                           'password' => MiqAePassword.new('test'))
    end

    it "obscures passwords" do
      original_attributes = @object.attributes.dup
      attributes = @service_object.attributes
      expect(attributes['password']).to eq('********')
      expect(@object.attributes).to eq(original_attributes)
    end
  end

  context "#inspect" do
    it "returns the class, id and name" do
      allow(@object).to receive(:object_name).and_return('fred')
      regex = /#<MiqAeMethodService::MiqAeServiceObject:0x(\w+) name:.\"(?<name>\w+)\">/
      match = regex.match(@service_object.inspect)
      expect(match[:name]).to eq('fred')
    end
  end
end

describe MiqAeMethodService::MiqAeService do
  context "#service_model" do
    let(:workspace) { double('ws', :persist_state_hash => {}) }
    let(:miq_ae_service) { described_class.new(workspace) }
    let(:prefix) { "MiqAeMethodService::MiqAeService" }

    it "loads base model" do
      allow(workspace).to receive(:disable_rbac)
      expect(miq_ae_service.service_model(:VmOrTemplate)).to   be(MiqAeMethodService::MiqAeServiceVmOrTemplate)
      expect(miq_ae_service.service_model(:vm_or_template)).to be(MiqAeMethodService::MiqAeServiceVmOrTemplate)
    end

    it "loads sub-classed model" do
      allow(workspace).to receive(:disable_rbac)
      expect(miq_ae_service.service_model(:Vm)).to be(MiqAeMethodService::MiqAeServiceVm)
      expect(miq_ae_service.service_model(:vm)).to be(MiqAeMethodService::MiqAeServiceVm)
    end

    it "loads model with mapped name" do
      allow(workspace).to receive(:disable_rbac)
      expect(miq_ae_service.service_model(:ems)).to be(MiqAeMethodService::MiqAeServiceExtManagementSystem)
    end

    it "loads name-spaced model by mapped name" do
      allow(workspace).to receive(:disable_rbac)
      MiqAeMethodService::Deprecation.silence do
        expect(miq_ae_service.service_model(:ems_openstack)).to be(
          MiqAeMethodService::MiqAeServiceManageIQ_Providers_Openstack_CloudManager)
        expect(miq_ae_service.service_model(:vm_openstack)).to  be(
          MiqAeMethodService::MiqAeServiceManageIQ_Providers_Openstack_CloudManager_Vm)
      end
    end

    it "loads name-spaced model by fully-qualified name" do
      allow(workspace).to receive(:disable_rbac)
      expect(miq_ae_service.service_model(:ManageIQ_Providers_Openstack_CloudManager)).to    be(
        MiqAeMethodService::MiqAeServiceManageIQ_Providers_Openstack_CloudManager)
      expect(miq_ae_service.service_model(:ManageIQ_Providers_Openstack_CloudManager_Vm)).to be(
        MiqAeMethodService::MiqAeServiceManageIQ_Providers_Openstack_CloudManager_Vm)
    end

    it "raises error on invalid service_model name" do
      allow(workspace).to receive(:disable_rbac)
      expect { miq_ae_service.service_model(:invalid_model) }.to raise_error(NameError)
    end

    it "loads all mapped models" do
      allow(workspace).to receive(:disable_rbac)
      MiqAeMethodService::MiqAeService::LEGACY_MODEL_NAMES.values.each do |model_name|
        expect { "MiqAeMethodService::MiqAeService#{model_name}".constantize }.to_not raise_error
      end
    end

    it "loads cloud networks" do
      allow(workspace).to receive(:disable_rbac)
      items = %w(
        ManageIQ_Providers_Openstack_NetworkManager_CloudNetwork
        ManageIQ_Providers_Openstack_NetworkManager_CloudNetwork_Private
        ManageIQ_Providers_Openstack_NetworkManager_CloudNetwork_Public
      )
      items.each do |name|
        expect(miq_ae_service.vmdb(name)).to be("#{prefix}#{name}".constantize)
      end
    end

    context 'state_var methods' do
      before do
        allow(workspace).to(receive(:disable_rbac))
      end
      it '#set_state_var' do
        miq_ae_service.set_state_var('name', 'value')
        validation_hash = { 'name' => 'value' }
        expect(miq_ae_service.instance_eval { @persist_state_hash }).to(eq(validation_hash))
      end
      it '#get_state_var' do
        expect(miq_ae_service.get_state_var('name')).to(eq(nil))
        miq_ae_service.instance_eval { @persist_state_hash = { 'name' => 'value' } }
        expect(miq_ae_service.get_state_var('name')).to(eq('value'))
      end
      it '#delete_state_var' do
        miq_ae_service.instance_eval { @persist_state_hash = { 'name' => 'value' } }
        miq_ae_service.delete_state_var('name')
        expect(miq_ae_service.instance_eval { @persist_state_hash }).to(eq({}))
      end
      it '#state_var_exist?' do
        expect(miq_ae_service.state_var_exist?('name')).to(be_falsey)
        miq_ae_service.instance_eval { @persist_state_hash = { 'name' => 'value' } }
        expect(miq_ae_service.state_var_exist?('name')).to(be_truthy)
      end
    end

    it 'get_state_vars' do
      allow(workspace).to(receive(:disable_rbac))
      expect(miq_ae_service.get_state_vars).to eq({})
      miq_ae_service.instance_eval { @persist_state_hash = { 'var1' => 'value1', 'var2' => 'value2' } }
      expect(miq_ae_service.get_state_vars).to eq('var1' => 'value1', 'var2' => 'value2')
    end

    it 'ansible_stats_vars' do
      allow(workspace).to(receive(:disable_rbac))
      expect(miq_ae_service.ansible_stats_vars).to eq({})
      miq_ae_service.instance_eval { @persist_state_hash = { 'ansible_stats_var1' => 'value1', 'ansible_stats_var2' => 'value2', 'var3' => 'value3' } }
      expect(miq_ae_service.ansible_stats_vars).to eq('var1' => 'value1', 'var2' => 'value2')
    end
  end

  context 'service_var method' do
    let(:user) { FactoryBot.create(:user_with_group) }

    def invoke_ae
      MiqAeEngine.instantiate("/EVM/AUTOMATE/test1?Service::service=#{@service.id}", user)
    end

    before do
      Spec::Support::MiqAutomateHelper.create_service_model_method('SPEC_DOMAIN', 'EVM', 'AUTOMATE', 'test1', 'test')
      @ae_method = ::MiqAeMethod.first

      @parent = FactoryBot.create(:service)
      @service = FactoryBot.create(:service, :service => @parent)
    end

    it 'set_service_var' do
      method = "$evm.set_service_var('var1', 'value1')"
      @ae_method.update(:data => method)
      invoke_ae

      @parent.reload
      @service.reload

      expect(@parent.options.dig(:service_vars, 'var1')).to eq('value1')
      expect(@service.options.dig(:service_vars)).not_to be_present
    end

    it 'service_var_exists?' do
      @parent.update(:options => {:service_vars => {'var1' => 'value1'}})
      method = "$evm.root['var1_exists'] = $evm.service_var_exists?('var1'); $evm.root['var2_exists'] = $evm.service_var_exists?('var2')"
      @ae_method.update(:data => method)
      result = invoke_ae

      expect(result.root['var1_exists']).to be true
      expect(result.root['var2_exists']).to be false
    end

    it 'get_service_var' do
      @parent.update(:options => {:service_vars => {'var1' => 'value1'}})
      method = "$evm.root['var1'] = $evm.get_service_var('var1'); $evm.root['var2'] = $evm.get_service_var('var2')"
      @ae_method.update(:data => method)
      result = invoke_ae

      expect(result.root['var1']).to eq('value1')
      expect(result.root['var2']).to be nil
    end

    it 'delete_service_var' do
      @parent.update(:options => {:service_vars => {'var1' => 'value1'}})
      method = "$evm.delete_service_var('var1'); $evm.root['var1'] = $evm.get_service_var('var1')"
      @ae_method.update(:data => method)
      result = invoke_ae

      expect(result.root['var1']).to be nil
    end
  end
end

describe MiqAeMethodService::MiqAeService do
  context "#prepend_namespace=" do
    let(:options) { {} }
    let(:workspace) { double("MiqAeEngine::MiqAeWorkspaceRuntime", :root => options) }
    let(:miq_ae_service) { described_class.new(workspace) }
    let(:ns) { "fred" }

    it "set namespace" do
      allow(workspace).to receive(:disable_rbac)
      allow(workspace).to receive(:persist_state_hash).and_return({})
      expect(workspace).to receive(:prepend_namespace=).with(ns)

      miq_ae_service.prepend_namespace = ns
    end
  end
  context "create notifications" do
    before do
      NotificationType.seed
      allow(User).to receive_messages(:server_timezone => 'UTC')
      allow(workspace).to receive(:disable_rbac)
    end

    let(:options) { {} }
    let(:workspace) do
      double("MiqAeEngine::MiqAeWorkspaceRuntime", :root               => options,
                                                   :ae_user            => user,
                                                   :persist_state_hash => {})
    end
    let(:miq_ae_service) { described_class.new(workspace) }
    let(:user) { FactoryBot.create(:user_with_group) }
    let(:vm) { FactoryBot.create(:vm) }
    let(:msg_text) { 'mary had a little lamb' }

    context "#create_notification!" do
      it "invalid type" do
        expect { miq_ae_service.create_notification!(:type => :invalid_type, :subject => vm) }
          .to raise_error(ArgumentError, "Invalid notification type specified")
      end

      it "invalid subject" do
        expect { miq_ae_service.create_notification!(:type => :vm_retired, :subject => 'fred') }
          .to raise_error(ArgumentError, "Subject must be a valid Active Record object")
      end

      it "default type of automate_user_info" do
        result = miq_ae_service.create_notification!(:message => msg_text)
        expect(result).to be_kind_of(MiqAeMethodService::MiqAeServiceNotification)
      end

      it "type of automate_user_info" do
        result = miq_ae_service.create_notification!(:level => 'success', :audience => 'user', :message => 'test')
        expect(result).to be_kind_of(MiqAeMethodService::MiqAeServiceNotification)
      end

      it "type of automate_tenant_info" do
        expect(user).to receive(:tenant).and_return(Tenant.root_tenant)
        result = miq_ae_service.create_notification!(:level => 'success', :audience => 'tenant', :message => 'test')
        expect(result).to be_kind_of(MiqAeMethodService::MiqAeServiceNotification)
      end

      it "type of automate_global_info" do
        result = miq_ae_service.create_notification!(:level => 'success', :audience => 'global', :message => 'test')
        expect(result).to be_kind_of(MiqAeMethodService::MiqAeServiceNotification)
      end
    end

    context "#create_notification" do
      it "invalid type" do
        expect { miq_ae_service.create_notification(:type => :invalid_type, :subject => vm) }
          .not_to raise_error
      end

      it "invalid subject" do
        expect { miq_ae_service.create_notification(:type => :vm_retired, :subject => 'fred') }
          .not_to raise_error
      end

      it "default type of automate_user_info" do
        result = miq_ae_service.create_notification(:message => msg_text)
        expect(result).to be_kind_of(MiqAeMethodService::MiqAeServiceNotification)
        ui_representation = result.object_send(:to_h)
        expect(ui_representation).to include(:text     => '%{message}',
                                             :bindings => a_hash_including(:message=>{:text=> msg_text}))
      end

      it "type of automate_user_info" do
        result = miq_ae_service.create_notification(:level => 'success', :audience => 'user', :message => 'test')
        expect(result).to be_kind_of(MiqAeMethodService::MiqAeServiceNotification)
      end

      it "type of automate_tenant_info" do
        expect(user).to receive(:tenant).and_return(Tenant.root_tenant)
        result = miq_ae_service.create_notification(:level => 'success', :audience => 'tenant', :message => 'test')
        expect(result).to be_kind_of(MiqAeMethodService::MiqAeServiceNotification)
      end

      it "type of automate_global_info" do
        result = miq_ae_service.create_notification(:level => 'success', :audience => 'global', :message => 'test')
        expect(result).to be_kind_of(MiqAeMethodService::MiqAeServiceNotification)
      end
    end
  end
end
