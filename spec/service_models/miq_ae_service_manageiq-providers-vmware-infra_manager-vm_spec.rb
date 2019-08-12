describe MiqAeMethodService::MiqAeServiceManageIQ_Providers_Vmware_InfraManager_Vm do
  let(:vm)             { FactoryBot.create(:vm_vmware) }
  let(:folder)         { FactoryBot.create(:ems_folder) }
  let(:service_vm)     { MiqAeMethodService::MiqAeServiceManageIQ_Providers_Vmware_InfraManager_Vm.find(vm.id) }
  let(:service_folder) { MiqAeMethodService::MiqAeServiceEmsFolder.find(folder.id) }

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

  it "#set_number_of_cpus" do
    service_vm.set_number_of_cpus(1)

    expect(MiqQueue.first).to have_attributes(
      @base_queue_options.merge(
        :method_name => 'set_number_of_cpus',
        :args        => [1])
    )
  end

  it "#set_memory" do
    service_vm.set_memory(100)

    expect(MiqQueue.first).to have_attributes(
      @base_queue_options.merge(
        :method_name => 'set_memory',
        :args        => [100])
    )
  end

  it "#move_into_folder" do
    service_vm.move_into_folder(service_folder)

    expect(MiqQueue.first).to have_attributes(
      @base_queue_options.merge(
        :method_name => 'move_into_folder'
      )
    )
  end

  it "#add_disk" do
    service_vm.add_disk('disk_1', 100, :thin_provisioned => true)

    expect(MiqQueue.first).to have_attributes(
      @base_queue_options.merge(
        :method_name => 'add_disk',
        :args        => ['disk_1', 100, :thin_provisioned => true])
    )
  end

  it "#remove_from_disk async"do
    service_vm.remove_from_disk(false)

    expect(MiqQueue.first).to have_attributes(
      @base_queue_options.merge(
        :method_name => 'vm_destroy',
        :args        => [])
    )
  end
end
