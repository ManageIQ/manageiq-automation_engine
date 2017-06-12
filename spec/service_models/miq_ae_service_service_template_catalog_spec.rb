module MiqAeServiceServiceTemplateCatalogSpec
  describe MiqAeMethodService::MiqAeServiceServiceTemplateCatalog do
    context "associations" do
      before do
        service_template_catalog = FactoryGirl.create(:service_template_catalog)
        @service_service_template_catalog = MiqAeMethodService::MiqAeServiceServiceTemplateCatalog.find(service_template_catalog.id)
      end

      it "#service_templates" do
        service_template = FactoryGirl.create(:service_template, :service_template_catalog_id => @service_service_template_catalog.id)
        first_service_template = @service_service_template_catalog.service_templates.first

        expect(first_service_template).to be_kind_of(MiqAeMethodService::MiqAeServiceServiceTemplate)
        expect(first_service_template.id).to eq(service_template.id)
      end
    end
  end
end
