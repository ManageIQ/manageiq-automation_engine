describe MiqAeYamlImportZipfs do
  let(:domain_a) { "DomainA" }
  let(:domain_b) { "DomainB" }
  let(:ns)       { "Namespace1" }
  let(:klass)    { "MyClass" }

  let(:mixin) { MiqAeYamlImportExportMixin }

  # Paths inside the zip
  let(:domain_a_yaml)    { "#{domain_a}/#{mixin::DOMAIN_YAML_FILENAME}" }
  let(:domain_b_yaml)    { "#{domain_b}/#{mixin::DOMAIN_YAML_FILENAME}" }
  let(:ns_a_yaml)        { "#{domain_a}/#{ns}/#{mixin::NAMESPACE_YAML_FILENAME}" }
  let(:ns_b_yaml)        { "#{domain_b}/#{ns}/#{mixin::NAMESPACE_YAML_FILENAME}" }
  let(:class_a_yaml)     { "#{domain_a}/#{ns}/#{klass}#{mixin::CLASS_DIR_SUFFIX}/#{mixin::CLASS_YAML_FILENAME}" }
  let(:class_b_yaml)     { "#{domain_b}/#{ns}/#{klass}#{mixin::CLASS_DIR_SUFFIX}/#{mixin::CLASS_YAML_FILENAME}" }

  let(:zip_path) do
    require 'zip/filesystem'
    t = Tempfile.new(['ae_zipfs_spec', '.zip'])
    path = t.path
    t.close

    Zip::File.open(path, :create => true) do |zf|
      [
        domain_a_yaml, domain_b_yaml,
        ns_a_yaml,     ns_b_yaml,
        class_a_yaml,  class_b_yaml
      ].each do |entry_path|
        parts = entry_path.split('/')
        parts.each_with_index do |_, idx|
          dir = parts[0..(idx - 1)].join('/')
          zf.dir.mkdir(dir) if idx.positive? && !zf.file.directory?(dir)
        end
        zf.file.open(entry_path, "w") { |f| f.puts({}.to_yaml) }
      end
    end

    path
  end

  subject(:zipfs) { MiqAeYamlImportZipfs.new(domain_a, 'zip_file' => zip_path) }

  after { FileUtils.rm_f(zip_path) }

  def entry_names
    zipfs.instance_variable_get(:@sorted_entries).map(&:name)
  end

  describe "#remove_unrelated_entries" do
    it "removes entries that do not belong to the given domain" do
      zipfs.remove_unrelated_entries(domain_a)
      expect(entry_names).to all(start_with(domain_a))
    end

    it "retains entries that belong to the given domain" do
      zipfs.remove_unrelated_entries(domain_a)
      expect(entry_names).to include(domain_a_yaml, ns_a_yaml, class_a_yaml)
    end

    it "removes entries from other domains" do
      zipfs.remove_unrelated_entries(domain_a)
      expect(entry_names).not_to include(domain_b_yaml, ns_b_yaml, class_b_yaml)
    end
  end

  describe "#remove_entry and #update_sorted_entries" do
    it "removes a specific entry and refreshes the sorted list" do
      target = zipfs.all_namespace_files.find { |e| e.name == ns_a_yaml }
      zipfs.remove_entry(target)
      zipfs.update_sorted_entries
      expect(entry_names).not_to include(ns_a_yaml)
    end

    it "leaves other entries intact after removing one" do
      target = zipfs.all_namespace_files.find { |e| e.name == ns_a_yaml }
      zipfs.remove_entry(target)
      zipfs.update_sorted_entries
      expect(entry_names).to include(ns_b_yaml)
    end
  end

  describe "#all_namespace_files" do
    it "returns entry objects for all namespace yaml files across all domains" do
      names = zipfs.all_namespace_files.map(&:name)
      expect(names).to match_array([ns_a_yaml, ns_b_yaml])
    end
  end

  describe "#all_class_files" do
    it "returns entry objects for all class yaml files across all domains" do
      names = zipfs.all_class_files.map(&:name)
      expect(names).to match_array([class_a_yaml, class_b_yaml])
    end
  end
end
