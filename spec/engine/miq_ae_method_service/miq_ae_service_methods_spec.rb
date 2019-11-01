describe MiqAeMethodService::MiqAeServiceMethods do
  before(:each) do
    @user = FactoryBot.create(:user_with_group)
    Spec::Support::MiqAutomateHelper.create_service_model_method('SPEC_DOMAIN', 'EVM', 'AUTOMATE', 'test1', 'test')
    @ae_method     = ::MiqAeMethod.first
    @ae_result_key = 'foo'
  end

  def invoke_ae
    MiqAeEngine.instantiate("/EVM/AUTOMATE/test1", @user)
  end

  context "exposes ActiveSupport methods" do
    it "nil#blank?" do
      method   = "$evm.root['#{@ae_result_key}'] = nil.blank?"
      @ae_method.update_attributes(:data => method)
      ae_object = invoke_ae.root(@ae_result_key)
      expect(ae_object).to be_truthy
    end
  end

  context "#send_mail" do
    let(:options) do
      {
        :to           => "wilma@bedrock.gov",
        :from         => "fred@bedrock.gov",
        :body         => "What are we having for dinner?",
        :content_type => "text/fred",
        :bcc          => "thing1@bedrock.gov",
        :cc           => "thing2@bedrock.gov",
        :subject      => "Dinner"
      }
    end

    it "sends mail synchronous" do
      method = "$evm.root['#{@ae_result_key}'] = $evm.execute(:send_email, #{options[:to].inspect}, #{options[:from].inspect}, #{options[:subject].inspect}, #{options[:body].inspect}, {:bcc => #{options[:bcc].inspect}, :cc => #{options[:cc].inspect}, :content_type => #{options[:content_type].inspect}})"
      @ae_method.update_attributes(:data => method)
      stub_const('MiqAeMethodService::MiqAeServiceMethods::SYNCHRONOUS', true)
      expect(GenericMailer).to receive(:deliver).with(:automation_notification, options).once
      ae_object = invoke_ae.root(@ae_result_key)
      expect(ae_object).to be_truthy
    end

    it "sends mail asynchronous" do
      miq_server = EvmSpecHelper.local_miq_server
      MiqRegion.seed
      miq_server.server_roles << FactoryBot.create(:server_role, :name => 'notifier')

      method = "$evm.root['#{@ae_result_key}'] = $evm.execute(:send_email, #{options[:to].inspect}, #{options[:from].inspect}, #{options[:subject].inspect}, #{options[:body].inspect}, {:bcc => #{options[:bcc].inspect}, :cc => #{options[:cc].inspect}, :content_type => #{options[:content_type].inspect}})"
      @ae_method.update_attributes(:data => method)
      stub_const('MiqAeMethodService::MiqAeServiceMethods::SYNCHRONOUS', false)
      expect(MiqQueue).to receive(:put).with(
        :class_name  => 'GenericMailer',
        :method_name => "deliver",
        :args        => [:automation_notification, options],
        :role        => "notifier"
      ).once
      ae_object = invoke_ae.root(@ae_result_key)
      expect(ae_object).to be_truthy
    end
  end

  it "#snmp_trap_v1" do
    to      = "wilma@bedrock.gov"
    from    = "fred@bedrock.gov"
    inputs  = {:to => to, :from => from}
    method   = "$evm.root['#{@ae_result_key}'] = $evm.execute(:snmp_trap_v1, #{inputs.inspect})"
    @ae_method.update_attributes(:data => method)

    stub_const('MiqAeMethodService::MiqAeServiceMethods::SYNCHRONOUS', true)
    expect(MiqSnmp).to receive(:trap_v1).with(inputs).once
    ae_object = invoke_ae.root(@ae_result_key)
    expect(ae_object).to be_truthy

    stub_const('MiqAeMethodService::MiqAeServiceMethods::SYNCHRONOUS', false)
    expect(MiqQueue).to receive(:put).with(
        :class_name  => "MiqSnmp",
        :method_name => "trap_v1",
        :args        => [inputs],
        :role        => "notifier",
        :zone        => nil).once
    ae_object = invoke_ae.root(@ae_result_key)
    expect(ae_object).to be_truthy
  end

  it "#snmp_trap_v2" do
    to      = "wilma@bedrock.gov"
    from    = "fred@bedrock.gov"
    inputs  = {:to => to, :from => from}
    method   = "$evm.root['#{@ae_result_key}'] = $evm.execute(:snmp_trap_v2, #{inputs.inspect})"
    @ae_method.update_attributes(:data => method)

    stub_const('MiqAeMethodService::MiqAeServiceMethods::SYNCHRONOUS', true)
    expect(MiqSnmp).to receive(:trap_v2).with(inputs).once
    ae_object = invoke_ae.root(@ae_result_key)
    expect(ae_object).to be_truthy

    stub_const('MiqAeMethodService::MiqAeServiceMethods::SYNCHRONOUS', false)
    expect(MiqQueue).to receive(:put).with(
        :class_name  => "MiqSnmp",
        :method_name => "trap_v2",
        :args        => [inputs],
        :role        => "notifier",
        :zone        => nil).once
    ae_object = invoke_ae.root(@ae_result_key)
    expect(ae_object).to be_truthy
  end

  it "#vm_templates" do
    method   = "$evm.root['#{@ae_result_key}'] = $evm.execute(:vm_templates)"
    @ae_method.update_attributes(:data => method)

    expect(invoke_ae.root(@ae_result_key)).to be_empty

    v1 = FactoryBot.create(:vm_vmware, :ems_id => 42, :vendor => 'vmware')
    t1 = FactoryBot.create(:template_vmware, :ems_id => 42)
    ae_object = invoke_ae.root(@ae_result_key)
    expect(ae_object).to be_kind_of(Array)
    expect(ae_object.length).to eq(1)
    expect(ae_object.first.id).to eq(t1.id)
  end

  it "#category_exists?" do
    category = "flintstones"
    method   = "$evm.root['#{@ae_result_key}'] = $evm.execute(:category_exists?, #{category.inspect})"
    @ae_method.update_attributes(:data => method)

    expect(invoke_ae.root(@ae_result_key)).to be_falsey

    FactoryBot.create(:classification, :name => category)
    expect(invoke_ae.root(@ae_result_key)).to be_truthy
  end

  def category_create_script
    <<-'RUBY'
    options = {:name => 'flintstones',
               :description => 'testing'}
    $evm.root['foo'] = $evm.execute(:category_create, options)
    RUBY
  end

  it "#category_create" do
    @ae_method.update_attributes(:data => category_create_script)

    expect(invoke_ae.root(@ae_result_key)).to be_truthy
  end

  it "#tag_exists?" do
    ct = FactoryBot.create(:classification_department_with_tags)
    method = "$evm.root['#{@ae_result_key}'] = $evm.execute(:tag_exists?, #{ct.name.inspect}, #{ct.entries.first.name.inspect})"
    @ae_method.update_attributes(:data => method)

    expect(invoke_ae.root(@ae_result_key)).to be_truthy
  end

  it "#tag_create" do
    ct = FactoryBot.create(:classification_department_with_tags)
    method = "$evm.root['#{@ae_result_key}'] = $evm.execute(:tag_create, #{ct.name.inspect}, {:name => 'fred', :description => 'ABC'})"
    @ae_method.update_attributes(:data => method)

    expect(invoke_ae.root(@ae_result_key)).to be_truthy
    ct.reload
    expect(ct.entries.collect(&:name).include?('fred')).to be_truthy
  end

  context "#tag_delete!" do
    let(:ct) { FactoryBot.create(:classification_department_with_tags) }
    let(:entry_name) { ct.entries.first.name }

    it "could delete tag if it is not assigned" do
      tag_name = "/managed/#{ct.name}/#{entry_name}"
      expect(Tag.exists?(:name => tag_name)).to be_truthy
      method = "$evm.root['#{@ae_result_key}'] = $evm.execute(:tag_delete!, #{ct.name.inspect}, #{entry_name.inspect})"
      @ae_method.update(:data => method)

      expect(invoke_ae.root(@ae_result_key)).to be_truthy
      expect(Tag.exists?(:name => tag_name)).to be_falsey
    end

    it "could not delete tag if it is assigned" do
      assignment_tag = "/chargeback_rate/assigned_to/vm/tag/managed/#{ct.name}/#{entry_name}"
      Tag.create!(:name => assignment_tag)
      expect(Tag.exists?(:name => assignment_tag)).to be_truthy

      method = "$evm.root['#{@ae_result_key}'] = $evm.execute(:tag_delete!, #{ct.name.inspect}, #{entry_name.inspect})"
      @ae_method.update(:data => method)

      expect { invoke_ae.root(@ae_result_key) }.to raise_error(MiqAeException::UnknownMethodRc)
      expect(Tag.exists?(:name => assignment_tag)).to be_truthy
    end

    it "raises error if entry does not exist" do
      entry_not_exist = "entry_not_exist"
      tag_name = "/managed/#{ct.name}/#{entry_not_exist}"
      expect(Tag.exists?(:name => tag_name)).to be_falsey
      method = "$evm.root['#{@ae_result_key}'] = $evm.execute(:tag_delete!, #{ct.name.inspect}, #{entry_not_exist.inspect})"
      @ae_method.update(:data => method)

      expect { invoke_ae.root(@ae_result_key) }.to raise_error(MiqAeException::UnknownMethodRc)
    end
  end

  context "#tag_delete" do
    let(:ct) { FactoryBot.create(:classification_department_with_tags) }
    let(:entry_name) { ct.entries.first.name }

    it "could delete tag if it is not assigned" do
      tag_name = "/managed/#{ct.name}/#{entry_name}"
      expect(Tag.exists?(:name => tag_name)).to be_truthy
      method = "$evm.root['#{@ae_result_key}'] = $evm.execute(:tag_delete, #{ct.name.inspect}, #{entry_name.inspect})"
      @ae_method.update(:data => method)

      expect(invoke_ae.root(@ae_result_key)).to be true
      expect(Tag.exists?(:name => tag_name)).to be_falsey
    end

    it "return falses if the tag is assigned" do
      assignment_tag = "/chargeback_rate/assigned_to/vm/tag/managed/#{ct.name}/#{entry_name}"
      Tag.create!(:name => assignment_tag)
      expect(Tag.exists?(:name => assignment_tag)).to be_truthy

      method = "$evm.root['#{@ae_result_key}'] = $evm.execute(:tag_delete, #{ct.name.inspect}, #{entry_name.inspect})"
      @ae_method.update(:data => method)

      expect(invoke_ae.root(@ae_result_key)).to be false
      expect(Tag.exists?(:name => assignment_tag)).to be_truthy
    end

    it "returns false if entry does not exist" do
      entry_not_exist = "entry_not_exist"
      tag_name = "/managed/#{ct.name}/#{entry_not_exist}"
      expect(Tag.exists?(:name => tag_name)).to be_falsey
      method = "$evm.root['#{@ae_result_key}'] = $evm.execute(:tag_delete, #{ct.name.inspect}, #{entry_not_exist.inspect})"
      @ae_method.update(:data => method)

      expect(invoke_ae.root(@ae_result_key)).to be false
    end
  end

  context "#create_service_provision_request" do
    let(:options) { {:fred => :flintstone} }
    let(:svc_options) { {:dialog_style => "medium"} }
    let(:user) { FactoryBot.create(:user_with_group) }
    let(:template) { FactoryBot.create(:service_template_ansible_playbook) }
    let(:miq_request) { FactoryBot.create(:service_template_provision_request) }
    let(:svc_template) do
      MiqAeMethodService::MiqAeServiceServiceTemplate.find(template.id)
    end
    let(:workspace) do
      double("MiqAeEngine::MiqAeWorkspaceRuntime",
             :root               => options,
             :persist_state_hash => {},
             :ae_user            => user)
    end
    let(:miq_ae_service) { MiqAeMethodService::MiqAeService.new(workspace) }

    it "create service request" do
      allow(workspace).to receive(:disable_rbac)
      allow(ServiceTemplate).to receive(:find).with(template.id).and_return(template)
      expect(template).to receive(:provision_request).with(user, svc_options).and_return(miq_request)

      result = miq_ae_service.execute(:create_service_provision_request, svc_template, svc_options)
      expect(result).to be_kind_of(MiqAeMethodService::MiqAeServiceMiqRequest)
    end
  end

  context "#create_retire_request" do
    let(:options) { {:fred => :flintstone} }
    let(:user) { FactoryBot.create(:user_with_group) }
    let(:workspace) do
      double("MiqAeEngine::MiqAeWorkspaceRuntime",
             :root               => options,
             :persist_state_hash => {},
             :ae_user            => user)
    end
    let(:miq_ae_service) { MiqAeMethodService::MiqAeService.new(workspace) }

    before do
      allow(workspace).to receive(:disable_rbac)
    end

    %w[OrchestrationStack Service Vm].each do |klass|
      it "with retireable #{klass}" do
        obj = FactoryBot.create(klass.underscore.to_sym)
        svc_obj = "MiqAeMethodService::MiqAeService#{klass}".constantize.find(obj.id)
        expect(klass.constantize).to receive(:make_retire_request)
          .with(obj.id, user).and_return(FactoryBot.create("#{klass.underscore}_retire_request".to_sym, :requester => user))

        result = miq_ae_service.execute(:create_retire_request, svc_obj)
        expect(result).to be_kind_of(MiqAeMethodService::MiqAeServiceMiqRequest)
      end
    end

    it "with non-retireable class" do
      obj = FactoryBot.create(:host)
      svc_obj = MiqAeMethodService::MiqAeServiceHost.find(obj.id)
      expect { miq_ae_service.execute(:create_retire_request, svc_obj) }.to raise_error(MiqAeException::MethodNotFound)
    end
  end
end
