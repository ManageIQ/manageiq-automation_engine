describe MiqAeMethodService::MiqAeServicePhysicalServer do
  it '#turn_on_loc_led' do
    expect(described_class.instance_methods).to include(:turn_on_loc_led)
  end

  it '#turn_off_loc_led' do
    expect(described_class.instance_methods).to include(:turn_off_loc_led)
  end

  it '#power_on' do
    expect(described_class.instance_methods).to include(:power_on)
  end

  it '#power_off' do
    expect(described_class.instance_methods).to include(:power_off)
  end

  describe '#emstype' do
    before { allow(ems.class).to receive(:ems_type).and_return('THE_EMS_TYPE') }

    let(:server) { FactoryBot.create(:physical_server, :ext_management_system => ems) }
    let(:ems)    { FactoryBot.create(:ems_redfish_physical_infra) }

    subject { MiqAeMethodService::MiqAeServicePhysicalServer.find(server.id) }

    it 'passes on to ems' do
      expect(subject.emstype).to eq('THE_EMS_TYPE')
    end
  end
end
