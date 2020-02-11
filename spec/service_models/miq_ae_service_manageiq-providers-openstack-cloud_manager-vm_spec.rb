describe MiqAeMethodService::MiqAeServiceManageIQ_Providers_Openstack_CloudManager_Vm do
  let(:vm)         { FactoryBot.create(:vm_openstack, :ext_management_system => FactoryBot.create(:ems_openstack)) }
  let(:service_vm) { described_class.find(vm.id) }

  before do
    @base_queue_options = {
      :class_name  => vm.class.name,
      :instance_id => vm.id,
      :zone        => vm.my_zone,
      :role        => 'ems_operations',
      :queue_name  => vm.queue_name_for_ems_operations,
      :task_id     => nil
    }
  end

  it "#attach_volume" do
    service_vm.attach_volume('volume1', '/device/path')

    expect(MiqQueue.last).to have_attributes(
      @base_queue_options.merge(
        :method_name => 'attach_volume',
        :args        => ['volume1', '/device/path']
      )
    )
  end

  it "#detach_volume" do
    service_vm.detach_volume('volume1')

    expect(MiqQueue.last).to have_attributes(
      @base_queue_options.merge(
        :method_name => 'detach_volume',
        :args        => ['volume1']
      )
    )
  end
end
