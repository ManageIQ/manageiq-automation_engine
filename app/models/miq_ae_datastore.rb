module MiqAeDatastore
  XML_VERSION = "1.0".freeze
  XML_VERSION_MIN_SUPPORTED = "1.0".freeze
  MANAGEIQ_DOMAIN = "ManageIQ".freeze
  MANAGEIQ_PRIORITY = 0
  DATASTORE_DIRECTORY = Rails.root.join('db/fixtures/ae_datastore')
  DEFAULT_OBJECT_NAMESPACE = "$".freeze
  TEMP_DOMAIN_PREFIX = "TEMP_DOMAIN".freeze
  ALL_DOMAINS = "*".freeze
  PRESERVED_ATTRS = [:priority, :enabled, :source].freeze

  # deprecated module
  module Import
    def self.load_xml(xml, domain = MiqAeDatastore.temp_domain)
      MiqAeDatastore.xml_deprecated_warning
      XmlImport.load_xml(xml, domain)
    end
  end

  TMP_DIR = Rails.root.join("tmp/miq_automate_engine").expand_path

  def self.temp_domain
    "#{TEMP_DOMAIN_PREFIX}-#{SecureRandom.uuid}"
  end

  def self.xml_deprecated_warning
    msg = "[DEPRECATION] xml export/import is deprecated. Please use the YAML format instead.  At #{caller[1]}"
    $log.warn msg
    warn msg
  end

  def self.default_backup_filename
    "datastore_#{format_timezone(Time.now, Time.zone, "fname")}.zip"
  end

  def self.backup(options)
    options['zip_file'] ||= default_backup_filename
    export_options = options.slice('zip_file', 'overwrite', 'tenant')
    MiqAeExport.new(ALL_DOMAINS, export_options).export
  end

  def self.convert(filename, domain_name = temp_domain, export_options = {})
    if export_options['zip_file'].blank? && export_options['export_dir'].blank? && export_options['yaml_file'].blank?
      export_options['export_dir'] = TMP_DIR.to_s
    end

    File.open(filename, 'r') do |handle|
      XmlYamlConverter.convert(handle, domain_name, export_options)
    end
  end

  def self.upload(fd, name = nil, domain_name = ALL_DOMAINS)
    name ||= fd.original_filename
    name      = Pathname(name).basename.sub_ext('.zip')
    upload_to = TMP_DIR.join(name)
    TMP_DIR.mkpath

    _log.info("Uploading Datastore Import to file <#{upload_to}>")

    IO.copy_stream(fd, upload_to)
    fd.close

    _log.info("Upload complete (size=#{upload_to.size})")

    begin
      import_yaml_zip(upload_to.to_s, domain_name, User.current_tenant)
    ensure
      upload_to.delete
    end
  end

  def self.import(fname, domain = temp_domain)
    _, t = Benchmark.realtime_block(:total_time) { XmlImport.load_file(fname, domain) }
    _log.info("Import #{fname}...Complete - Benchmark: #{t.inspect}")
  end

  def self.restore(fname)
    _log.info("Restore from #{fname}...Starting")
    MiqAeDatastore.reset
    MiqAeImport.new(ALL_DOMAINS, 'zip_file' => fname, 'preview' => false, 'restore' => true).import
    _log.info("Restore from #{fname}...Complete")
  end

  def self.import_yaml_zip(fname, domain, tenant)
    t = Benchmark.realtime_block(:total_time) do
      import_options = {'zip_file' => fname, 'preview' => false,
                        'mode'     => 'add', 'tenant'  => tenant}
      MiqAeImport.new(domain, import_options).import
    end
    _log.info("Import #{fname}...Complete - Benchmark: #{t.inspect}")
  end

  def self.import_yaml_dir(dirname, domain, tenant)
    t = Benchmark.realtime_block(:total_time) do
      import_options = {'import_dir' => dirname, 'preview' => false,
                        'mode'       => 'add',   'restore' => true,
                        'tenant'     => tenant}
      MiqAeImport.new(domain, import_options).import
    end
    _log.info("Import from #{dirname}...Complete - Benchmark: #{t.inspect}")
  end

  def self.export(tenant)
    require 'tempfile'
    temp_export = Tempfile.new('ae_export')
    MiqAeDatastore.backup('zip_file' => temp_export.path, 'overwrite' => true, 'tenant' => tenant)
    File.read(temp_export.path)
  ensure
    temp_export.close
    temp_export.unlink
  end

  def self.export_class(ns, class_name)
    XmlExport.class_to_xml(ns, class_name)
  end

  def self.export_namespace(ns)
    XmlExport.namespace_to_xml(ns)
  end

  def self.reset
    _log.info("Clearing datastore")
    [MiqAeClass, MiqAeField, MiqAeInstance, MiqAeNamespace, MiqAeMethod, MiqAeValue].each(&:delete_all)
  end

  def self.reset_default_namespace
    ns = MiqAeNamespace.lookup_by_fqname(DEFAULT_OBJECT_NAMESPACE)
    ns.destroy if ns
    seed_default_namespace
  end

  private_class_method def self.reset_domain(datastore_dir, domain_name, tenant)
    _log.info("Resetting domain #{domain_name} from #{datastore_dir}")
    ns = MiqAeDomain.lookup_by_fqname(domain_name)
    ns.destroy if ns
    import_yaml_dir(datastore_dir, domain_name, tenant)
    if domain_name.downcase == MANAGEIQ_DOMAIN.downcase
      ns = MiqAeDomain.lookup_by_fqname(MANAGEIQ_DOMAIN)
      ns.update!(:source   => MiqAeDomain::SYSTEM_SOURCE, :enabled => true,
                            :priority => MANAGEIQ_PRIORITY) if ns
    end
  end

  private_class_method def self.reset_domains(domains)
    domains.each { |domain| reset_domain(domain.datastores_path.to_s, domain.name, Tenant.root_tenant) }
  end

  def self.seed_default_namespace
    default_ns   = MiqAeNamespace.create!(:name => DEFAULT_OBJECT_NAMESPACE)
    object_class = default_ns.ae_classes.create!(:name => 'Object')

    default_method_options = {:language => 'ruby', :scope => 'instance', :location => 'builtin'}
    object_class.ae_methods.create!(default_method_options.merge(:name => 'log_object'))
    object_class.ae_methods.create!(default_method_options.merge(:name => 'log_workspace'))

    email_method = object_class.ae_methods.create!(default_method_options.merge(:name => 'send_email'))
    email_method.inputs.build([{:name => 'to',      :priority => 1, :datatype => 'string'},
                               {:name => 'from',    :priority => 2, :datatype => 'string'},
                               {:name => 'subject', :priority => 3, :datatype => 'string'},
                               {:name => 'body',    :priority => 4, :datatype => 'string'}])
    email_method.save!
  end

  def self.reset_to_defaults
    saved_attrs = preserved_attrs_for_domains

    reset_all_domains

    restore_attrs_for_domains(saved_attrs)
    reset_default_namespace
    MiqAeDomain.reset_priorities
  end

  private_class_method def self.domains
    legacy_domains + plugin_domains
  end

  private_class_method def self.default_domains
    domains.select(&:system?)
  end

  private_class_method def self.legacy_domains
    domain_files = DATASTORE_DIRECTORY.join('*', MiqAeDomain::DOMAIN_YAML_FILENAME)
    domains = Dir.glob(domain_files).map do |domain_file|
      Vmdb::Plugins::AutomateDomain.new(File.dirname(domain_file))
    end
    filter_domains(domains)
  end

  private_class_method def self.plugin_domains
    filter_domains(Vmdb::Plugins.automate_domains)
  end

  private_class_method def self.filter_domains(domains)
    return domains unless Rails.env.test? && ENV["AUTOMATE_DOMAINS"]

    filter = ENV["AUTOMATE_DOMAINS"].split(",")
    domains.select { |i| filter.include?(i.name) }
  end

  private_class_method def self.domain_names
    domains.collect(&:name)
  end

  def self.default_domain_names
    default_domains.collect(&:name)
  end

  private_class_method def self.reset_all_domains
    reset_domains(domains)
  end

  def self.seed
    ns = MiqAeDomain.lookup_by_fqname(MANAGEIQ_DOMAIN)
    unless ns
      _log.info("Seeding ManageIQ domain...")
      begin
        reset_to_defaults
      rescue => err
        _log.error("Seeding... Reset failed, #{err.message}")
      else
        _log.info("Seeding... Complete")
      end
    end
    _log.info("Resetting domain priorities at startup...")
    MiqAeDomain.reset_priorities
  end

  def self.get_homonymic_across_domains(user, arclass, fqname, enabled = nil)
    return [] if fqname.blank?
    options = arclass == ::MiqAeClass ? {:has_instance_name => false} : {}
    _, ns, klass, name = ::MiqAeEngine::MiqAePath.get_domain_ns_klass_inst(fqname, options)
    name = klass if arclass == ::MiqAeClass
    MiqAeDatastore.get_sorted_matching_objects(user, arclass, ns, klass, name, enabled)
  end

  def self.get_sorted_matching_objects(user, arclass, ns, klass, name, enabled)
    options = arclass == ::MiqAeClass ? {:has_instance_name => false} : {}
    domains = user.current_tenant.visible_domains
    matches = arclass.where("lower(name) = ?", name.downcase).collect do |obj|
      get_domain_index_object(domains, obj, klass, ns, enabled, options)
    end.compact
    matches.sort_by { |a| a[:index] }.collect { |v| v[:obj] }
  end

  def self.get_domain_index_object(domains, obj, klass, ns, enabled, options)
    domain, nsd, klass_name, = ::MiqAeEngine::MiqAePath.get_domain_ns_klass_inst(obj.fqname, options)
    return if !klass_name.casecmp(klass).zero? || !nsd.casecmp(ns).zero?
    domain_index = get_domain_index(domains, domain, enabled)
    {:obj => obj, :index => domain_index} if domain_index
  end

  def self.get_domain_index(domains, name, enabled)
    domains.to_a.index do |dom|
      dom.name.casecmp(name).zero? && (enabled ? dom.enabled == enabled : true)
    end
  end

  def self.preserved_attrs_for_domains
    MiqAeDomain.all.each_with_object({}) do |dom, h|
      next if dom.name.downcase == MANAGEIQ_DOMAIN.downcase
      h[dom.name] = PRESERVED_ATTRS.each_with_object({}) { |attr, ih| ih[attr] = dom[attr] }
    end
  end

  def self.restore_attrs_for_domains(hash)
    hash.each { |dom, attrs| MiqAeDomain.lookup_by_fqname(dom, false).update(attrs) }
  end

  def self.path_includes_domain?(path, options = {})
    nsd, = ::MiqAeEngine::MiqAePath.split(path, options)
    MiqAeNamespace.lookup_by_fqname(nsd, false) != nil
  end
end
