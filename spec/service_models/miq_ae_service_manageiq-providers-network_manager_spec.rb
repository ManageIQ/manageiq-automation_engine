describe MiqAeMethodService::MiqAeServiceManageIQ_Providers_NetworkManager do
  let(:ems) { FactoryBot.create(:ems_cloud) }
  let(:network_manager) { ems.network_manager }
  let(:svc_network_manager) { MiqAeMethodService::MiqAeServiceManageIQ_Providers_NetworkManager.find(network_manager.id) }

  it "#create_network_router async" do
    @base_queue_options = {
      :class_name  => network_manager.class.name,
      :instance_id => network_manager.id,
      :zone        => network_manager.my_zone,
      :role        => 'ems_operations',
      :queue_name  => network_manager.queue_name_for_ems_operations,
      :task_id     => nil
    }
    svc_network_manager.create_network_router("thing")

    expect(MiqQueue.last).to have_attributes(
      @base_queue_options.merge(
        :method_name => 'create_network_router',
        :args        => ["thing"]
      )
    )
  end
end
