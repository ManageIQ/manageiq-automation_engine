describe MiqAeMethodService::MiqAeServiceEmsFolder do
  let(:folder) { FactoryBot.create(:ems_folder, :ext_management_system => FactoryBot.create(:ext_management_system)) }
  let(:host) { FactoryBot.create(:host) }
  let(:svc_folder) { MiqAeMethodService::MiqAeServiceEmsFolder.find(folder.id) }

  it "#register_host async" do
    @base_queue_options = {
      :class_name  => folder.class.name,
      :instance_id => folder.id,
      :zone        => folder.my_zone,
      :role        => 'ems_operations',
      :queue_name  => folder.queue_name_for_ems_operations,
      :task_id     => nil
    }
    svc_folder.register_host(host)

    expect(MiqQueue.last).to have_attributes(
      @base_queue_options.merge(
        :method_name => 'register_host',
        :args        => [host.id]
      )
    )
  end
end
