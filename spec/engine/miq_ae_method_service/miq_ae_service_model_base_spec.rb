describe MiqAeMethodService::MiqAeServiceModelBase do
  describe '.ar_model?' do
    it 'returns true for direct subclasses of ApplicationRecord' do
      expect(described_class.ar_model?(VmOrTemplate)).to be true
    end

    it 'returns true for grand-child subclasses of ApplicationRecord' do
      expect(described_class.ar_model?(Vm)).to be true
    end

    it 'returns false for classes not derived from ApplicationRecord' do
      expect(described_class.ar_model?(MiqRequestWorkflow)).to be false
    end

    it 'returns false for NilClass' do
      expect(described_class.ar_model?(nil)).to be false
    end
  end

  describe '.service_model_name_to_model' do
    it 'returns active record model for known class' do
      expect(described_class.service_model_name_to_model('MiqAeServiceVmOrTemplate')).to be VmOrTemplate
    end

    it 'returns nil for unknown class' do
      expect(described_class.service_model_name_to_model('MiqAeServiceVmOrNotVm')).to be_nil
    end
  end

  describe '.model_to_service_model_name' do
    it 'converts base model without namespaces' do
      expect(described_class.model_to_service_model_name(VmOrTemplate))
        .to eq 'MiqAeServiceVmOrTemplate'
    end

    it 'converts subclassed model with namespaces' do
      expect(described_class.model_to_service_model_name(ManageIQ::Providers::InfraManager::Vm))
        .to eq 'MiqAeServiceManageIQ_Providers_InfraManager_Vm'
    end
  end

  describe '.model_to_file_name' do
    it 'converts base model without namespaces' do
      expect(described_class.model_to_file_name(VmOrTemplate))
        .to eq 'miq_ae_service_vm_or_template.rb'
    end

    it 'converts subclassed model with namespaces' do
      expect(described_class.model_to_file_name(ManageIQ::Providers::InfraManager::Vm))
        .to eq 'miq_ae_service_manageiq-providers-infra_manager-vm.rb'
    end
  end

  describe '.model_to_file_path' do
    it 'converts base model without namespaces' do
      expect(described_class.model_to_file_path(VmOrTemplate))
        .to eq File.join(described_class::SERVICE_MODEL_PATH, 'miq_ae_service_vm_or_template.rb')
    end

    it 'converts subclassed model with namespaces' do
      expect(described_class.model_to_file_path(ManageIQ::Providers::InfraManager::Vm))
        .to eq File.join(described_class::SERVICE_MODEL_PATH, 'miq_ae_service_manageiq-providers-infra_manager-vm.rb')
    end
  end

  describe '.create_service_model_from_name' do
    it 'returns nil for names without miq_ae_service prefix' do
      expect(described_class.create_service_model_from_name(:VmOrTemplate)).to be_nil
    end

    context 'with a test class' do
      it 'return nil when not a subclass of ApplicationRecord' do
        expect(described_class.create_service_model_from_name(:MiqAeServiceMiqAeServiceModelSpec_TestInteger)).to be_nil
      end

      it 'returns a service_model class derived from MiqAeServiceModelBase' do
        test_class = described_class.create_service_model_from_name(:MiqAeServiceMiqAeServiceModelSpec_TestApplicationRecord)
        expect(test_class.name).to eq('MiqAeMethodService::MiqAeServiceMiqAeServiceModelSpec_TestApplicationRecord')
        expect(test_class.superclass.name).to eq('MiqAeMethodService::MiqAeServiceModelBase')
      end

      it 'returns a service_model class derived from MiqAeServiceVmOrTemplate' do
        test_class = described_class.create_service_model_from_name(:MiqAeServiceMiqAeServiceModelSpec_TestVmOrTemplate)
        expect(test_class.name).to eq('MiqAeMethodService::MiqAeServiceMiqAeServiceModelSpec_TestVmOrTemplate')
        expect(test_class.superclass.name).to eq('MiqAeMethodService::MiqAeServiceVmOrTemplate')
      end

      it 'does not list private attributes' do
        expect(MiqAeMethodService::MiqAeServiceModelBase).not_to(receive(:expose).with('properties'))
        obj     = MiqAeServiceModelSpec::TestPrivateAttrExpose.create
        svc_obj = described_class.model_name_from_active_record_model(MiqAeServiceModelSpec::TestPrivateAttrExpose).constantize.find(obj.id)
        expect(svc_obj.methods.include?(:properties)).to(eq(false))
      end
    end
  end

  describe 'YAML import/export' do
    let(:service)     { FactoryBot.create(:service, :name => 'test_service') }
    let(:svc_service) { MiqAeMethodService::MiqAeServiceService.find(service.id) }

    it 'exports only class name and ID' do
      expect(svc_service.to_yaml)
        .to eq("--- !ruby/object:#{svc_service.class.name}\nid: #{svc_service.id}\n")
    end

    it 'loads object from yaml' do
      expect(YAML.safe_load(svc_service.to_yaml)).to eq(svc_service)
    end

    it 'loads invalid svc_model for objects without related ar_model' do
      yaml = svc_service.to_yaml
      service.delete
      model_from_yaml = YAML.safe_load(yaml)
      expect { model_from_yaml.reload }.to raise_error(
        NoMethodError,
        "undefined method `reload' for nil:NilClass"
      )
    end
  end

  context 'with a VM service model' do
    let(:service_model) { MiqAeMethodService::MiqAeServiceManageIQ_Providers_InfraManager_Vm }

    describe '.ar_subclass_associations' do
      it `does not return the tags association` do
        expect(service_model.ar_model_associations).to_not include(:tags)
      end

      it `does not include associations from superclass` do
        expect(service_model.ar_model_associations).to_not include(service_model.superclass.ar_model_associations)
      end
    end

    describe '.associations' do
      it 'does not contain duplicate associations' do
        associations = service_model.associations
        expect(associations.count).to eq(associations.uniq.count)
      end

      it 'does not return the tags associations' do
        expect(service_model.associations).to_not include(:tags)
      end
    end
  end
end

module MiqAeServiceModelSpec
  class TestInteger < ::Integer; end
  class TestApplicationRecord < ::ApplicationRecord; end
  class TestVmOrTemplate < ::VmOrTemplate; end
  class TestPrivateAttrExpose < ::ApplicationRecord
    self.table_name = 'generic_objects'

    def self.attribute_names
      ['properties']
    end

    private

    def properties
      super
    end
  end
end
