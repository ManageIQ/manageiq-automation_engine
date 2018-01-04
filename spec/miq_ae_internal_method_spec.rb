describe MiqAeEngine::MiqAeInternalMethod do
  describe "run" do
    let(:root_hash) { { 'name' => 'Flintstone' } }
    let(:root_object) { Spec::Support::MiqAeMockObject.new(root_hash) }
    let(:persist_hash) { {} }
    let(:method_name) { "Freddy_Kreuger" }
    let(:description) { "Yaba Daba Doo" }
    let(:object_str) { "${/#miq_provision}" }

    let(:workspace) do
      double("MiqAeEngine::MiqAeWorkspaceRuntime", :root               => root_object,
                                                   :persist_state_hash => persist_hash,
                                                   :ae_user            => user)
    end

    let(:user) do
      FactoryGirl.create(:user_with_group, :userid   => "admin",
                                           :settings => {:display => { :timezone => "UTC"}})
    end

    let(:result_obj) { "." }
    let(:result_attribute) { "BammBammRubble" }

    let(:vm) { FactoryGirl.create(:vm_vmware, :name => "VM1") }

    let(:output) do
      {
        :result_attr => result_attribute,
        :result_obj  => result_obj,
      }
    end

    let(:aem)    { double("AEM", :options => options, :name => method_name) }
    let(:inputs) { { 'name' => 'Fred' } }

    let(:mpr) { FactoryGirl.create(:miq_provision_request, :requester => user, :description => description) }

    let(:svc_mpr) { MiqAeMethodService::MiqAeServiceMiqProvisionRequest.find(mpr.id) }

    let(:test_obj) { Spec::Support::MiqAeMockObject.new(:workspace => workspace) }

    let(:options) do
      {
        :output_parameters => output,
        :method            => object_method_name,
        :target            => object_str
      }
    end

    before do
      allow(workspace).to receive(:get_obj_from_path).and_return(test_obj)
    end

    context "instance method" do
      before do
        allow(test_obj).to receive(:substitute_value).with(object_str, nil, true).and_return(svc_mpr)
      end
      let(:root_hash) { { 'name' => 'Flintstone', 'miq_provision' => svc_mpr} }
      let(:object_method_name) { "description" }

      context "method defined" do
        it "success" do
          described_class.new(aem, test_obj, {}).run
          expect(test_obj[result_attribute]).to eq(description)
        end
      end

      context "method not defined" do
        let(:object_method_name) { "nada" }
        it "raises exception" do
          expect { described_class.new(aem, test_obj, {}).run }.to raise_exception(MiqAeException::MethodNotFound)
        end
      end

      context "result attribute not defined" do
        let(:result_attribute) { nil }

        it "uses default attribute name" do
          described_class.new(aem, test_obj, {}).run
          expect(test_obj['result']).to eq(description)
        end
      end

      context "invalid args, no object or class" do
        let(:options) { {} }
        it "raises exception" do
          expect { described_class.new(aem, test_obj, {}).run }.to raise_exception(MiqAeException::MethodParmMissing)
        end
      end

      context "invalid args, no method name specified" do
        let(:object_method_name) { "" }
        it "raises exception" do
          expect { described_class.new(aem, test_obj, {}).run }.to raise_exception(MiqAeException::MethodParmMissing)
        end
      end

      context "target object missing" do
        before do
          allow(workspace).to receive(:get_obj_from_path).and_return(nil)
        end

        it "raises exception" do
          expect { described_class.new(aem, test_obj, {}).run }.to raise_exception(MiqAeException::ObjectNotFound)
        end
      end

      context "substitution returns an empty string" do
        before do
          allow(test_obj).to receive(:substitute_value).with(object_str, nil, true).and_return(nil)
        end

        it "raises exception" do
          expect { described_class.new(aem, test_obj, inputs).run }.to raise_exception(ArgumentError)
        end
      end

      context "method runtime failure" do
        before do
          allow(svc_mpr).to receive(:bail).and_raise(StandardError)
        end
        let(:object_method_name) { "bail" }

        it "raises exception" do
          expect { described_class.new(aem, test_obj, {}).run }.to raise_exception(StandardError)
        end
      end
    end

    context "class method" do
      let(:options) do
        {
          :output_parameters => output,
          :method            => "name",
          :target_class      => svc_mpr.class.name
        }
      end

      it "runs successfully" do
        described_class.new(aem, test_obj, {}).run
        expect(test_obj[result_attribute]).to eq(svc_mpr.class.name)
      end
    end

    context "state machine" do
      before do
        allow(svc_mpr).to receive(:bail).and_raise(MiqAeException::MiqAeRetryException)
        allow(test_obj).to receive(:substitute_value).with(object_str, nil, true).and_return(svc_mpr)
      end

      let(:object_method_name) { "bail" }
      let(:root_hash) { { 'ae_state_started' => '1' } }
      let(:output) { { :retry_exception => true } }
      let(:options) do
        {
          :output_parameters => output,
          :method            => object_method_name,
          :target            => object_str
        }
      end

      context "default retry interval" do
        it "default retry interval" do
          described_class.new(aem, test_obj, {}).run

          expect(root_object['ae_result']).to eq('retry')
          expect(root_object['ae_retry_interval']).to eq(1.minute)
        end
      end

      context "set retry interval" do
        let(:output) { { :retry_exception => true, :retry_interval => 10.minutes} }
        it "default retry interval" do
          described_class.new(aem, test_obj, {}).run

          expect(root_object['ae_result']).to eq('retry')
          expect(root_object['ae_retry_interval']).to eq(10.minutes)
        end
      end

      context "trap any error" do
        before do
          allow(svc_mpr).to receive(:bail).and_raise(StandardError)
        end

        it "set ae_result to error" do
          described_class.new(aem, test_obj, {}).run
          expect(root_object['ae_result']).to eq('error')
        end
      end
    end

    context "state var" do
      let(:result_obj) { "state_var" }
      let(:options) do
        {
          :output_parameters => output,
          :method            => "name",
          :target_class      => svc_mpr.class.name
        }
      end

      it "sets the state var" do
        expect(workspace).to receive(:set_state_var).with(result_attribute, svc_mpr.class.name)
        described_class.new(aem, test_obj, {}).run
      end
    end

    context "method called with correct parameters" do
      before do
        allow(test_obj).to receive(:substitute_value).with(object_str, nil, true).and_return(svc_mpr)
      end
      let(:object_method_name) { "ka_boom" }

      it "validate method params" do
        expect(svc_mpr).to receive(:ka_boom).with(inputs).and_return(true)

        described_class.new(aem, test_obj, inputs).run
      end
    end

    context "vmdb object" do
      before do
        allow(test_obj).to receive(:substitute_value).with(object_str, nil, true).and_return(svc_mpr)
        allow(svc_mpr).to receive(:get_me_a_vm).and_return(vm)
      end

      let(:object_method_name) { "get_me_a_vm" }

      context "result in object" do
        it "returns a service vm object" do
          described_class.new(aem, test_obj, {}).run

          expect(test_obj[result_attribute].id).to eq(vm.id)
          expect(test_obj[result_attribute].class).to eq(MiqAeMethodService::MiqAeServiceManageIQ_Providers_Vmware_InfraManager_Vm)
        end
      end

      context "result in state var" do
        let(:result_obj) { "state_var" }
        let(:result_attr) { nil }

        it "returns a service vm object" do
          expect(workspace).to receive(:set_state_var).with("VmOrTemplate::#{result_attribute}", vm.id)
          described_class.new(aem, test_obj, {}).run
        end
      end
    end
  end
end
