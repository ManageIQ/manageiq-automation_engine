describe MiqAeMethodService::MiqAeServiceManageIQ_Providers_Openstack_CloudManager_Vm do
  let(:vm)         { FactoryBot.create(:vm_openstack) }
  let(:service_vm) { described_class.find(vm.id) }

  before do
    zone = FactoryBot.create(:zone)
    allow_any_instance_of(Vm).to receive(:my_zone).and_return(zone.name)
    allow(MiqServer).to receive(:my_zone).and_return(zone.name)
    @base_queue_options = {
      :class_name  => vm.class.name,
      :instance_id => vm.id,
      :zone        => zone.name,
      :role        => 'ems_operations',
      :task_id     => nil
    }
  end

  it "#attach_volume" do
    service_vm.attach_volume('volume1', '/device/path')

    expect(MiqQueue.first).to have_attributes(
      @base_queue_options.merge(
        :method_name => 'attach_volume',
        :args        => ['volume1', '/device/path'])
    )
  end

  it "#detach_volume" do
    service_vm.detach_volume('volume1')

    expect(MiqQueue.first).to have_attributes(
      @base_queue_options.merge(
        :method_name => 'detach_volume',
        :args        => ['volume1'])
    )
  end
end
