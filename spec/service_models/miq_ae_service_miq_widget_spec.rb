module MiqAeServiceMiqWidgetSpec
  describe MiqAeMethodService::MiqAeServiceMiqWidget do
    it "#queue_generate_content" do
      miq_widget = FactoryGirl.create(:miq_widget)
      allow(MiqWidget).to receive(:find).with(miq_widget.id).and_return(miq_widget)
      service_miq_widget = MiqAeMethodService::MiqAeServiceMiqWidget.find(miq_widget.id)

      expect(miq_widget).to receive(:queue_generate_content)
      service_miq_widget.queue_generate_content
    end
  end
end
