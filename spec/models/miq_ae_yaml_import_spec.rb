describe MiqAeYamlImport do
  let(:domain) { "domain" }
  let(:options) { {} }
  let(:miq_ae_yaml_import) { described_class.new(domain, options) }
  let(:options) { {"overwrite" => true, "tenant" => Tenant.root_tenant, 'zip_file' => 'file'} }

  before do
    EvmSpecHelper.local_guid_miq_server_zone
  end

  describe "#new_domain_name_valid?" do
    context "when the options hash overwrite is true" do
      it "returns true" do
        expect(miq_ae_yaml_import.new_domain_name_valid?).to be_truthy
      end
    end
  end

  describe "transaction rollback" do
    context "#import" do
      let(:path) { "path" }
      it "old namespace is preserved" do
        dom = FactoryBot.create(:miq_ae_domain, :name => domain)
        domain_yaml = {
          'object_type' => 'domain',
          'version'     => '1.0',
          'object'      => {'attributes' => dom.attributes}
        }
        ns = FactoryBot.create(:miq_ae_namespace, :parent => dom)
        FactoryBot.create(:miq_ae_class, :namespace_id => ns.id)

        allow(miq_ae_yaml_import).to receive(:domain_folder).with(domain).and_return(path)
        allow(miq_ae_yaml_import).to receive(:namespace_files).with(path) { raise ArgumentError }
        allow(miq_ae_yaml_import).to receive(:read_domain_yaml).with(path, domain) { domain_yaml }
        expect { miq_ae_yaml_import.import }.to raise_exception(ArgumentError)
        dom.reload
        expect(dom.ae_namespaces.first.id).to eq(ns.id)
      end
    end
  end

  describe "#import" do
    let(:user) { FactoryBot.create(:user_with_group) }
    let(:path) { "path" }
    let(:dom_yaml) do
      {
        "object_type" => "domain",
        "version"     => 1.0,
        "object"      => {
          "attributes" => {
            "name"                => domain,
            "description"         => nil,
            "display_name"        => nil,
            "source"              => source,
            "top_level_namespace" => nil
          }
        }
      }
    end

    before do
      allow(miq_ae_yaml_import).to receive(:domain_folder).with(domain).and_return(path)
      allow(miq_ae_yaml_import).to receive(:namespace_files).with(path) { [] }
      allow(miq_ae_yaml_import).to receive(:read_domain_yaml).with(path, domain) { dom_yaml }
      User.current_user = user
    end

    def basic_validation(attributes = {})
      att = { :name => domain, :source => source }.merge(attributes)
      expect(MiqAeDomain.all.count).to eq(1)
      dom = MiqAeDomain.last
      expect(dom.name).to eq(att[:name])
      expect(dom.source).to eq(att[:source])
    end

    def create_test_domain(attributes = {})
      att = { :name => domain, :source => source }.merge(attributes)
      MiqAeDomain.create(att).save!
      FactoryBot.create(:miq_ae_namespace, :parent => MiqAeDomain.last)
    end

    context 'user source' do
      let(:source) { 'user' }

      it 'imports domain' do
        miq_ae_yaml_import.import
        basic_validation
      end

      it 'overwrites existing domains' do
        create_test_domain
        dom = miq_ae_yaml_import.import
        expect(dom.children).to eq([])
        basic_validation
      end

      it 'overwrites locked domains from git' do
        create_test_domain(:source => "#{source}_locked")
        options['zip_file'] = nil
        options['git_repository_id'] = 1
        dom = miq_ae_yaml_import.import
        expect(dom.children).to eq([])
        basic_validation(:source => "#{source}_locked")
      end

      it 'does not import into locked domain' do
        create_test_domain(:source => "#{source}_locked")
        expect { miq_ae_yaml_import.import }
          .to raise_error(MiqAeException::DomainNotAccessible, 'Cannot import into a locked domain.')
      end

      it 'does not overwrite system domains from git' do
        options['zip_file'] = nil
        options['git_repository_id'] = 1
        create_test_domain(:source => "system")
        expect { miq_ae_yaml_import.import }
          .to raise_error(MiqAeException::DomainNotAccessible, 'Git based system domain import is not supported.')
      end
    end

    context 'system source' do
      let(:source) { 'system' }
      let(:domain) { 'ManageIQ' }
      let(:path)   { domain }

      it 'imports domain' do
        miq_ae_yaml_import.import
        basic_validation
      end

      it 'overwrites existing domains' do
        create_test_domain
        dom = miq_ae_yaml_import.import
        expect(dom.children).to eq([])
        basic_validation
      end

      it 'does not import system domains from git' do
        options['zip_file'] = nil
        options['git_repository_id'] = 1
        expect { miq_ae_yaml_import.import }
          .to raise_error(MiqAeException::InvalidDomain, 'Git based system domain import is not supported.')
      end

      context 'with custom name' do
        let(:domain) { 'path' }
        let(:path)   { domain }

        it 'does not import' do
          expect { miq_ae_yaml_import.import }
            .to raise_error(MiqAeException::InvalidDomain, 'System domain import is not supported.')
        end
      end

      context 'with different destination name' do
        let(:options) do
          {
            "overwrite" => true,
            "tenant"    => Tenant.root_tenant,
            'zip_file'  => 'file',
            'import_as' => 'different_name'
          }
        end

        it 'does not import' do
          expect { miq_ae_yaml_import.import }
            .to raise_error(MiqAeException::InvalidDomain, 'Domain name change for a system domain import is not supported.')
        end
      end
    end
  end
end
