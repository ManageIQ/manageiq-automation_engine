describe MiqAeEngine::MiqAeObject do
  include Spec::Support::AutomationHelper

  before do
    MiqAeDatastore.reset
    @domain = 'SPEC_DOMAIN'
    FactoryBot.create(:miq_ae_domain, :name => @domain)
    @user = FactoryBot.create(:user_with_group)
    @model_data_dir = File.join(File.dirname(__FILE__), "data")
    EvmSpecHelper.import_yaml_model(File.join(@model_data_dir, "miq_ae_object_spec1"), @domain)
    @vm = FactoryBot.create(:vm_vmware)
    @ws = MiqAeEngine.instantiate("/SYSTEM/EVM/AUTOMATE/test1", @user)
    @miq_obj = described_class.new(@ws, "#{@domain}/SYSTEM/EVM", "AUTOMATE", "test1")
  end

  after(:each) do
    MiqAeDatastore.reset
  end

  it "#to_xml" do
    args = {'nil_arg' => nil, 'float_arg' => 5.98,
            'int_arg' => 10,  'string_arg' => 'Stringy',
            'svc_vm'  => MiqAeMethodService::MiqAeServiceManageIQ_Providers_Vmware_InfraManager_Vm.find(@vm.id)}

    @miq_obj.process_args_as_attributes(args)
    validate_xml(@miq_obj.to_xml, args)
  end

  def validate_xml(xml, args)
    hash = Hash.from_xml(xml)
    attrs = hash['MiqAeObject']['MiqAeAttribute']
    args.each do |key, value|
      expect(find_match(attrs, key, value)).to be_truthy
    end
  end

  def find_match(attrs, key, value)
    item = attrs.detect { |i| i['name'] == key }
    return false unless item

    item.delete('name')
    xml_class = item.keys.first
    type_match(value.class, xml_class) &&
      value_match(value, item[xml_class])
  end

  def type_match(original_class, xml_class_name)
    xml_class_name = xml_class_name.gsub(/-/, '::')
    /MiqAeMethodService::(?<cls>.*)/ =~ original_class.name
    cls &&= "MiqAeMethodService::#{xml_class_name}"
    cls ||= xml_class_name
    original_class == cls.constantize
  end

  def value_match(value, xml_value)
    service_model = value.class.name.start_with?("MiqAeMethodService::")
    return value.id.inspect == xml_value['id'] if service_model

    value == xml_value || value.inspect == xml_value
  end

  it "#process_args_as_attributes with a hash with no object reference" do
    result = @miq_obj.process_args_as_attributes("name" => "fred")
    expect(result["name"]).to be_kind_of(String)
    expect(result["name"]).to eq("fred")
  end

  it "#process_args_as_attributes with a hash with an object reference" do
    result = @miq_obj.process_args_as_attributes("VmOrTemplate::vm" => @vm.id.to_s)
    expect(result["vm_id"]).to eq(@vm.id.to_s)
    expect(result["vm"]).to be_kind_of(MiqAeMethodService::MiqAeServiceVmOrTemplate)
  end

  it "#process_args_as_attributes with a single element array" do
    result = @miq_obj.process_args_as_attributes("Array::vms" => "VmOrTemplate::#{@vm.id}")
    expect(result["vms"]).to be_kind_of(Array)
    expect(result["vms"].length).to eq(1)
  end

  it "#process_args_as_attributes with mixed types and case insensitive" do
    result = @miq_obj.process_args_as_attributes("Array::VMs" => "VmOrTemplate::#{@vm.id}",
                                                 "Name"       => "fred")
    expect(result["vms"]).to be_kind_of(Array)
    expect(result["vms"].length).to eq(1)
    expect(result["VMs"]).to be_nil
    expect(result["name"]).to eq("fred")
    expect(result["Name"]).to be_nil
  end

  it "#process_args_as_attributes with an array" do
    vm2 = FactoryBot.create(:vm_vmware)
    result = @miq_obj.process_args_as_attributes("Array::vms" => "VmOrTemplate::#{@vm.id}\x1FVmOrTemplate::#{vm2.id}")
    expect(result["vms"]).to be_kind_of(Array)
    expect(result["vms"].length).to eq(2)
  end

  describe "#process_args_as_attributes" do
    let(:result) { @miq_obj.process_args_as_attributes("Array::my_values" => my_values) }

    context "with an array containing invalid entries" do
      let(:my_values) { "VmOrTemplate::#{@vm.id}\x1Ffred::12\x1FVmOrTemplate::#{FactoryBot.create(:vm_vmware).id}" }

      it "raises an exception" do
        expect { @miq_obj.process_args_as_attributes("Array::vms" => my_values) }.to raise_exception MiqAeException::InvalidClass
      end
    end

    context "with an array containing empty entries" do
      let(:my_values) { "VmOrTemplate::#{@vm.id}\x1F\x1F\x1FVmOrTemplate::#{FactoryBot.create(:vm_vmware).id}" }

      it "ignores empty values and returns everything else" do
        expect(result["my_values"].size).to eq 2
        expect(result["my_values"][0].id).to eq @vm.id
      end
    end

    context "with an array including spaces after the seperator" do
      let(:my_values) { "integer::1\x1F integer::3\x1F integer::10" }

      it "stores the values as an array of strings" do
        expect(result["my_values"]).to eq([1, 3, 10])
      end
    end

    context "with an array including no spaces after the seperator" do
      let(:my_values) { "integer::1\x1Finteger::3\x1Finteger::10" }

      it "stores the values as an array of strings" do
        expect(result["my_values"]).to eq([1, 3, 10])
      end
    end

    context "with an array including commas inside" do
      let(:my_values) { "'1,1'\x1F\"3,3\"\x1Finteger::10" }

      it "stores the values as an array of strings" do
        expect(result["my_values"]).to eq(["'1,1'", "\"3,3\"", 10])
      end
    end

    context "with an array containing disparate objects" do
      let!(:my_values) do
        host    = FactoryBot.create(:host)
        ems     = FactoryBot.create(:ems_vmware)
        "VmOrTemplate::#{@vm.id}\x1FHost::#{host.id}\x1FExtManagementSystem::#{ems.id}"
      end

      it "stores the first value as a VM object" do
        expect(result["my_values"].first).to be_kind_of(MiqAeMethodService::MiqAeServiceVm)
      end

      it "stores the second value as a Host object" do
        expect(result["my_values"].second).to be_kind_of(MiqAeMethodService::MiqAeServiceHost)
      end

      it "stores the third value as a ExtManagementSystem object" do
        expect(result["my_values"].third).to be_kind_of(MiqAeMethodService::MiqAeServiceExtManagementSystem)
      end
    end

    context "with an array containing strings" do
      let(:my_values) { "abc\x1Fxyz\x1F\x1F1" }

      it "stores the values as an array of strings" do
        expect(result["my_values"]).to eq(%w[abc xyz 1])
      end
    end

    context "with an array containing strings and objects" do
      let(:my_values) { "abc\x1FVmOrTemplate::#{@vm.id}" }

      it "stores the first value as a string" do
        expect(result["my_values"].first).to eq("abc")
      end

      it "stores the second value as an MiqAeMethodService::MiqAeServiceVmOrTemplate" do
        expect(result["my_values"].second).to be_kind_of(MiqAeMethodService::MiqAeServiceVmOrTemplate)
      end
    end
  end

  it "disabled inheritance" do
    @user = FactoryBot.create(:user_with_group)
    create_state_ae_model(:name => 'LUIGI', :ae_class => 'CLASS1', :ae_namespace => 'A/C', :instance_name => 'FRED')
    klass = MiqAeClass.lookup_by_name('CLASS1')
    klass.update!(:inherits => '/LUIGI/A/C/missing')
    workspace = MiqAeEngine.instantiate("/A/C/CLASS1/FRED", @user)
    expect(workspace.root).not_to be_nil
  end

  context "#enforce_state_maxima" do
    it "should not raise an exception before exceeding max_time" do
      Timecop.freeze(Time.parse('2013-01-01 00:59:59 UTC')) do
        @ws.root['ae_state_started'] = '2013-01-01 00:00:00 UTC'
        expect { @miq_obj.enforce_state_maxima('max_time' => '1.hour') }.to_not raise_error
      end
    end

    it "should raise an exception after exceeding max_time" do
      Timecop.freeze(Time.parse('2013-01-01 01:00:00 UTC')) do
        @ws.root['ae_state_started'] = '2013-01-01 00:00:00 UTC'
        expect { @miq_obj.enforce_state_maxima('max_time' => '1.hour') }
          .to raise_error(RuntimeError, /exceeded maximum/)
      end
    end
  end
end

describe MiqAeEngine::MiqAeObject do
  include Spec::Support::AutomationHelper

  context "substitute_value" do
    let(:email_value) { '${/#miq_request.get_option(:email).upcase}' }
    let(:req_email_value) { '${/#user.email}' }
    let(:instance_name) { 'FRED' }
    let(:ae_instances) do
      {instance_name => {'email'     => {:value => email_value},
                         'req_email' => {:value => req_email_value}}}
    end

    let(:ae_fields) do
      {'email'     => {:aetype => 'attribute', :datatype => 'string'},
       'req_email' => {:aetype => 'attribute', :datatype => 'string'}}
    end

    let(:model) do
      create_ae_model(:name => 'LUIGI', :ae_class => 'BARNEY',
                      :ae_namespace => 'A/C',
                      :ae_fields => ae_fields, :ae_instances => ae_instances)
    end

    let(:user) { FactoryBot.create(:user_with_group, :email => 'requester@example.com') }
    let(:ems) { FactoryBot.create(:ems_vmware_with_authentication) }
    let(:vm_template) { FactoryBot.create(:template_vmware, :ext_management_system => ems) }
    let(:options) do
      {:src_vm_id => [vm_template.id, vm_template.name],
       :email     => "user@example.com"}
    end

    let(:request) do
      FactoryBot.create(:miq_provision_request,
                        :provision_type => 'template',
                        :state => 'pending', :status => 'Ok',
                        :src_vm_id => vm_template.id,
                        :requester => user, :options => options)
    end

    it "email address" do
      model
      ae_str = "/A/C/BARNEY/FRED?MiqRequest::miq_request=#{request.id},User::user=#{user.id}"
      workspace = MiqAeEngine.instantiate(ae_str, user)
      expect(workspace.root['email']).to eq('USER@EXAMPLE.COM')
      expect(workspace.root['req_email']).to eq('requester@example.com')
    end
  end
end

describe MiqAeEngine::MiqAeObject do
  include Spec::Support::AutomationHelper

  context "resolve vmdb objects" do
    let(:user) { FactoryBot.create(:user_with_group) }
    let(:ems) { FactoryBot.create(:ems_vmware_with_authentication) }
    let(:vm) { FactoryBot.create(:vm_vmware, :ext_management_system => ems) }
    let(:instance_name) { 'FRED' }
    let(:ae_instances) do
      {instance_name => {'vm'   => {:value => vm.id},
                         'user' => {:value => user.id},
                         'ems'  => {:value => ems.id}}}
    end

    let(:ae_fields) do
      {'vm'   => {:aetype => 'attribute', :datatype => 'vm'},
       'user' => {:aetype => 'attribute', :datatype => 'user'},
       'ems'  => {:aetype => 'attribute', :datatype => 'ems'}}
    end

    let(:ae_model) do
      create_ae_model(:name => 'LUIGI', :ae_class => 'BARNEY',
                      :ae_namespace => 'A/C',
                      :ae_fields => ae_fields, :ae_instances => ae_instances)
    end

    it "instantiate" do
      ae_model
      workspace = MiqAeEngine.instantiate('/A/C/BARNEY/FRED', user)

      expect(workspace.root['vm'].name).to eq(vm.name)
      expect(workspace.root['user'].name).to eq(user.name)
      expect(workspace.root['ems'].name).to eq(ems.name)
    end

    it "instantiate raises exception for invalid object ids" do
      ae_instances[instance_name]['ems'][:value] = 'nada'
      ae_model

      expect do
        MiqAeEngine.instantiate('/A/C/BARNEY/FRED', user)
      end.to raise_exception(MiqAeException::ServiceNotFound)
    end

    it "instantiate doesn't raise exception for nil values" do
      ae_instances[instance_name]['ems'][:value] = nil
      ae_model
      workspace = MiqAeEngine.instantiate('/A/C/BARNEY/FRED', user)

      expect(workspace.root['vm'].name).to eq(vm.name)
      expect(workspace.root['user'].name).to eq(user.name)
      expect(workspace.root['ems']).to be_nil
    end
  end
end

describe MiqAeEngine::MiqAeObject do
  context "password" do
    let(:p45) { "Pneumonoultramicroscopicsilicovolcanoconiosis" }
    let(:p45_encrypted) { MiqAePassword.encrypt(p45) }

    it "can decrypt passwords" do
      expect(described_class.convert_value_based_on_datatype(p45_encrypted, 'password').encStr).to eq(p45_encrypted)
    end

    it "raises exception for bogus passwords" do
      expect do
        described_class.convert_value_based_on_datatype('gobbledygook', 'password')
      end.to raise_exception(ManageIQ::Password::PasswordError)
    end
  end

  context "integer" do
    it "returns value to_i" do
      %w[Integer integer].each { |type| expect(described_class.convert_value_based_on_datatype("45", type)).to eq(45) }
    end
  end

  context "data type is nil" do
    it "returns original value" do
      test_value = "test_value"
      expect(described_class.convert_value_based_on_datatype(test_value, nil)).to eq(test_value)
    end
  end
end
