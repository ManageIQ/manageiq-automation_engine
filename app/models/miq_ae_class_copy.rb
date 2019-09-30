class MiqAeClassCopy
  include MiqAeCopyMixin
  DELETE_PROPERTIES = %w[updated_by updated_by_user_id updated_on id
                         created_on updated_on method_id owner class_id].freeze

  def initialize(class_fqname)
    @class_fqname = class_fqname
    @src_domain, @partial_ns, @ae_class = MiqAeClassCopy.split(@class_fqname, false)
    @src_class = MiqAeClass.lookup_by_fqname(@class_fqname)
    raise "Source class not found #{@class_fqname}" unless @src_class
  end

  def to_domain(domain, namespace = nil, overwrite = false)
    check_duplicity(domain, namespace, @src_class.name)
    @overwrite        = overwrite
    @target_ns_fqname = target_ns(domain, namespace)
    @target_name      = @src_class.name
    copy
  end

  def as(new_name, namespace = nil, overwrite = false)
    check_duplicity(@src_domain, namespace, new_name)
    @overwrite        = overwrite
    @target_ns_fqname = target_ns(@src_domain, namespace)
    @target_name      = new_name
    copy
  end

  def self.copy_multiple(ids, domain, namespace = nil, overwrite = false)
    new_ids = []
    MiqAeClass.transaction do
      ids.each do |id|
        class_obj = MiqAeClass.find(id)
        new_class = new(class_obj.fqname).to_domain(domain, namespace, overwrite)
        new_ids << new_class.id if new_class
      end
    end
    new_ids
  end

  private

  def target_ns(domain, namespace)
    return "#{domain}/#{@partial_ns}" if namespace.nil?

    ns_obj = MiqAeNamespace.lookup_by_fqname(namespace, false)
    ns_obj && !ns_obj.domain? ? namespace : "#{domain}/#{namespace}"
  end

  def copy
    validate
    create_class
    copy_schema
    @dest_class
  end

  def create_class
    ns = MiqAeNamespace.find_or_create_by_fqname(@target_ns_fqname, false)
    ns.save!
    @dest_class = MiqAeClass.create!(:namespace_id => ns.id,
                                     :name         => @target_name,
                                     :description  => @src_class.description,
                                     :type         => @src_class.type,
                                     :display_name => @src_class.display_name,
                                     :inherits     => @src_class.inherits,
                                     :visibility   => @src_class.visibility)
  end

  def copy_schema
    @dest_class.ae_fields = add_fields
    @dest_class.save!
  end

  def add_fields
    @src_class.ae_fields.collect do |src_field|
      attrs = src_field.attributes.reject { |k, _| DELETE_PROPERTIES.include?(k) }
      MiqAeField.new(attrs)
    end
  end

  def validate
    dest_class = MiqAeClass.lookup_by_fqname("#{@target_ns_fqname}/#{@target_name}")
    $log.info("Destination class: #{dest_class}")
    if dest_class
      $log.info("Overwrite flag: #{@overwrite}")
      if @overwrite
        dest_class.destroy
        $log.info("Should only print if destination class exists and got destroyed by overwrite")
      end
      raise "Destination Class already exists #{dest_class.fqname}" unless @overwrite
    end
  end

  def check_duplicity(domain, namespace, classname)
    $log.info("Domain: #{domain}, namespace: #{namespace}, classname: #{classname}")
    if domain.downcase == @src_domain.downcase && classname.downcase == @ae_class.downcase
      raise "Cannot copy class onto itself" if namespace.nil? || namespace.downcase == @partial_ns.downcase
    end
  end
end
