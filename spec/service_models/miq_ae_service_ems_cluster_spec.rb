describe MiqAeMethodService::MiqAeServiceEmsCluster do
  let(:cluster) { FactoryBot.create(:ems_cluster, :ext_management_system => FactoryBot.create(:ext_management_system)) }
  let(:host) { FactoryBot.create(:host) }
  let(:svc_cluster) { MiqAeMethodService::MiqAeServiceEmsCluster.find(cluster.id) }

  it "#show_url" do
    ui_url = stub_remote_ui_url

    expect(svc_cluster.show_url).to eq("#{ui_url}/ems_cluster/show/#{cluster.id}")
  end

  it "#backup_create async" do
    @base_queue_options = {
      :class_name  => cluster.class.name,
      :instance_id => cluster.id,
      :zone        => cluster.my_zone,
      :role        => 'ems_operations',
      :queue_name  => cluster.queue_name_for_ems_operations,
      :task_id     => nil
    }
    svc_cluster.register_host(host)

    expect(MiqQueue.last).to have_attributes(
      @base_queue_options.merge(
        :method_name => 'register_host',
        :args        => [host.id]
      )
    )
  end
end
