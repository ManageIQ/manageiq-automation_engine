describe MiqAeMethodService::MiqAeServiceStorage do
  let(:storage) { FactoryBot.create(:storage) }
  let(:svc_storage) { MiqAeMethodService::MiqAeServiceStorage.find(storage.id) }

  it "#show_url" do
    ui_url = stub_remote_ui_url

    expect(svc_storage.show_url).to eq("#{ui_url}/storage/show/#{storage.id}")
  end
end
