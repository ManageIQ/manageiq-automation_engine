describe MiqAeEngine::MiqAeBuiltinMethod do
  describe '.miq_check_policy_prevent' do
    let(:event)     { FactoryBot.create(:miq_event) }
    let(:svc_event) { MiqAeMethodService::MiqAeServiceEventStream.find(event.id) }
    let(:workspace) { double('WORKSPACE', :get_obj_from_path => { 'event_stream' => svc_event }) }
    let(:obj)       { double('OBJ', :workspace => workspace) }

    subject { described_class.send(:miq_check_policy_prevent, obj, {}) }

    it 'with policy not prevented' do
      expect { subject }.not_to raise_error
    end

    it 'with policy prevented' do
      event.update_attributes(:full_data => {:policy => {:prevented => true}})
      expect { subject }.to raise_error(MiqAeException::StopInstantiation)
    end
  end

  describe 'AE entrypoint calculation' do
    let(:obj)       { double('OBJ', :workspace => workspace) }
    let(:workspace) { double('WORKSPACE', :root => root) }
    let(:root)      { {} }

    context '/PhysicalInfrastructure/PhysicalServer/Lifecycle/Provisioning' do
      before do
        allow(obj).to receive(:[]).with(anything).and_return(nil)
        allow(obj).to receive(:[]).with('request').and_return('physical_server_provision')
      end

      let(:root)           { { 'miq_request' => miq_request, 'physical_server_provision_task' => provision_task } }
      let(:options)        { { :request_type => 'provision_physical_server' } }
      let(:miq_request)    { nil }
      let(:provision_task) { nil }

      context 'when physical_server_provision_request' do
        before { allow(PhysicalServerProvisionRequest).to receive(:===).with(miq_request).and_return(true) }
        let(:miq_request) { instance_double('MIQ_REQUEST', :source => nil) }

        it '.miq_parse_provider_category' do
          expect(root).to receive(:[]=).with('ae_provider_category', described_class::PHYSICAL_INFRA)
          described_class.miq_parse_provider_category(obj, nil)
        end

        it '.miq_parse_automation_request' do
          expect(obj).to receive(:[]=).with('target_component', 'PhysicalServer')
          expect(obj).to receive(:[]=).with('target_class', 'Lifecycle')
          expect(obj).to receive(:[]=).with('target_instance', 'Provisioning')
          described_class.miq_parse_automation_request(obj, nil)
        end
      end

      context 'when physical_server_provision_task' do
        let(:provision_task) { double('MIQ_TASK', 'options' => options, :base_model => PhysicalServerProvisionTask) }

        it '.miq_parse_provider_category' do
          expect(root).to receive(:[]=).with('ae_provider_category', described_class::PHYSICAL_INFRA)
          described_class.miq_parse_provider_category(obj, nil)
        end

        it '.miq_parse_automation_request' do
          expect(obj).to receive(:[]=).with('target_component', 'PhysicalServer')
          expect(obj).to receive(:[]=).with('target_class', 'Lifecycle')
          expect(obj).to receive(:[]=).with('target_instance', 'Provisioning')
          described_class.miq_parse_automation_request(obj, nil)
        end
      end
    end
  end
end
