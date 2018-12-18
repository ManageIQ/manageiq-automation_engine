def stub_remote_ui_url
  ui_url = "https://www.example.com"
  miq_region = FactoryBot.create(:miq_region)
  allow(MiqRegion).to receive(:my_region).and_return(miq_region)
  allow(miq_region).to receive(:remote_ui_url).and_return(ui_url)
  ui_url
end
