describe MiqAeMethodService::MiqAeServiceStorage do
  let(:storage) { FactoryBot.create(:storage) }
  let(:svc_storage) { MiqAeMethodService::MiqAeServiceStorage.find(storage.id) }

  it "#show_url" do
    ui_url = stub_remote_ui_url

    expect(svc_storage.show_url).to eq("#{ui_url}/storage/show/#{storage.id}")
  end

  it "#show_url returns nil when remote_ui_url is nil" do
    miq_region = FactoryBot.create(:miq_region)
    allow(MiqRegion).to receive(:my_region).and_return(miq_region)
    allow(miq_region).to receive(:remote_ui_url).and_return(nil)
    expect(svc_storage.show_url).to be_nil
  end
end
