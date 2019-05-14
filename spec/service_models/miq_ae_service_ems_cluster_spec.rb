describe MiqAeMethodService::MiqAeServiceEmsCluster do
  let(:cluster) { FactoryBot.create(:ems_cluster) }
  let(:svc_cluster) { MiqAeMethodService::MiqAeServiceEmsCluster.find(cluster.id) }

  it "#show_url" do
    ui_url = stub_remote_ui_url

    expect(svc_cluster.show_url).to eq("#{ui_url}/ems_cluster/show/#{cluster.id}")
  end
end
