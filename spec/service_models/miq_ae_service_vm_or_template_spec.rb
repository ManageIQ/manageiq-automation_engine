describe MiqAeMethodService::MiqAeServiceVmOrTemplate do
  let(:vm) { FactoryBot.create(:vm_or_template, :ext_management_system => FactoryBot.create(:ext_management_system)) }
  let(:svc_vm) { MiqAeMethodService::MiqAeServiceVmOrTemplate.find(vm.id) }

  it "#ems_custom_set async" do
    @base_queue_options = {
      :class_name  => vm.class.name,
      :instance_id => vm.id,
      :zone        => vm.my_zone,
      :role        => 'ems_operations',
      :queue_name  => vm.queue_name_for_ems_operations,
      :task_id     => nil
    }
    svc_vm.ems_custom_set("thing", "thing2")

    expect(MiqQueue.last).to have_attributes(
      @base_queue_options.merge(
        :method_name => 'set_custom_field',
        :args        => ["thing", "thing2"]
      )
    )
  end
end
