describe MiqAeMethodService::MiqAeServiceStorage do
  let(:storage) { FactoryGirl.create(:storage) }
  let(:svc_storage) { MiqAeMethodService::MiqAeServiceStorage.find(storage.id) }

  it "#show_url" do
    ui_url = "https://www.example.com"
    miq_region = FactoryGirl.create(:miq_region)
    allow(MiqRegion).to receive(:my_region).and_return(miq_region)
    allow(miq_region).to receive(:remote_ui_url).and_return(ui_url)

    expect(svc_storage.show_url).to eq("#{ui_url}/storage/show/#{storage.id}")
  end
end
