describe MiqAeMethodService::MiqAeServiceEmsCluster do
  let(:cluster) { FactoryGirl.create(:ems_cluster) }
  let(:svc_cluster) { MiqAeMethodService::MiqAeServiceEmsCluster.find(cluster.id) }

  it "#show_url" do
    ui_url = "https://www.example.com"
    miq_region = FactoryGirl.create(:miq_region)
    allow(MiqRegion).to receive(:my_region).and_return(miq_region)
    allow(miq_region).to receive(:remote_ui_url).and_return(ui_url)

    expect(svc_cluster.show_url).to eq("#{ui_url}/ems_cluster/show/#{cluster.id}")
  end
end
