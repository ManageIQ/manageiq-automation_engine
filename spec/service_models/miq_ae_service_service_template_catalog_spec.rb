module MiqAeServiceServiceTemplateCatalogSpec
  describe MiqAeMethodService::MiqAeServiceServiceTemplateCatalog do
    context "through an automation method" do
      before(:each) do
        Spec::Support::MiqAutomateHelper.create_service_model_method('SPEC_DOMAIN', 'EVM', 'AUTOMATE', 'test1', 'test')
        @ae_method = ::MiqAeMethod.first
        @ae_result_key = 'foo'
        @service_template_catalog = FactoryGirl.create(:service_template_catalog)
        @user = FactoryGirl.create(:user_with_group)
      end

      def invoke_ae
        MiqAeEngine.instantiate("/EVM/AUTOMATE/test1?ServiceTemplateCatalog::service_template_catalog=#{@service_template_catalog.id}", @user)
      end
    end

    context "associations" do
      before do
        service_template_catalog = FactoryGirl.create(:service_template_catalog)
        @service_service_template_catalog = MiqAeMethodService::MiqAeServiceServiceTemplateCatalog.find(service_template_catalog.id)
      end

      it "#service_templates" do
        service_template = FactoryGirl.create(:service_template, :service_template_catalog_id => @service_service_template_catalog.id)
        first_service_template = @service_service_template_catalog.service_templates.first

        expect(first_service_template).to be_kind_of(MiqAeMethodService::MiqAeServiceService)
        expect(first_service_template.id).to eq(service_template.id)
      end
    end
  end
end
