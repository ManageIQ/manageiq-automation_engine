describe MiqAeEngine::MiqAeBuiltinMethod::MiqAeTaskBuiltin do
  describe '.miq_check_provisioned' do
    let(:ems) { FactoryGirl.create(:ems_vmware_with_authentication) }
    let(:vm_template) { FactoryGirl.create(:template_vmware, :ext_management_system => ems) }
    let(:vm) { nil }
    let(:admin) { FactoryGirl.create(:user_with_group, :role => "admin") }
    let(:pr) do
      FactoryGirl.create(:miq_provision_request,
                         :requester => admin,
                         :src_vm_id => vm_template.id)
    end
    let(:options) { { :src_vm_id => [vm_template.id, vm_template.name] } }
    let(:status) { "Ok" }
    let(:state) { "pending" }
    let(:message_with_error) { "Error: Yabba Dabba Doo" }
    let(:message) { "Yabba Dabba Doo" }
    let(:miq_provision) do
      FactoryGirl.create(:miq_provision,
                         :userid       => admin.userid,
                         :miq_request  => pr,
                         :source       => vm_template,
                         :request_type => 'template',
                         :state        => state,
                         :vm           => vm,
                         :message      => message_with_error,
                         :options      => options,
                         :status       => status)
    end
    let(:svc_miq_provision) { MiqAeMethodService::MiqAeServiceMiqProvision.find(miq_provision.id) }
    let(:root_obj) { { 'miq_provision' => svc_miq_provision } }
    let(:workspace) { double('WORKSPACE', :root => root_obj) }
    let(:obj) { double('OBJ', :workspace => workspace) }

    context "invalid args" do
      let(:root_obj) { { } }
      it "raises exception" do
        expect do
          MiqAeEngine::MiqAeBuiltinMethod.miq_check_provisioned(obj, {})
        end.to raise_error(ArgumentError)
      end
    end

    it 'task still running' do
      MiqAeEngine::MiqAeBuiltinMethod.miq_check_provisioned(obj, 'ae_retry_interval' => 10)

      expect(root_obj['ae_result']).to eq('retry')
      expect(root_obj['ae_retry_interval']).to eq(10)
    end

    context 'task finished' do
      let(:status) { "Ok" }
      let(:state) { "finished" }
      let(:vm) { FactoryGirl.create(:vm_vmware) }

      it "normal exit" do
        MiqAeEngine::MiqAeBuiltinMethod.miq_check_provisioned(obj, {})

        expect(root_obj['ae_result']).to eq('ok')
      end
    end

    context 'task fails' do
      let(:status) { "Error" }
      let(:state) { "finished" }

      it "sets ae_reason" do
        MiqAeEngine::MiqAeBuiltinMethod.miq_check_provisioned(obj, {})

        expect(root_obj['ae_result']).to eq('error')
        expect(root_obj['ae_reason']).to eq(message)
      end
    end
  end
end
