module MiqAeEngine
  module MiqAeSerializeWorkspace
    def hash_workspace(path = nil)
      objs = path.nil? ? roots : get_obj_from_path(path)
      result = {}
      objs.each { |obj| to_hash_with_refs(obj, nil, result) }
      result
    end

    def to_hash_with_refs(obj, parent, result)
      key = parent ? obj.object_name : "root"
      system_attrs = parent ? {"::miq::parent" => parent } : {}
      result[key] = process_attributes(obj).merge(system_attrs)

      obj.children.each { |c| to_hash_with_refs(c, key, result) }
    end

    def process_attributes(obj)
      obj.attributes.each_with_object({}) do |(k, v), hash|
        next if v.nil?
        hash[k.to_s] = MiqAeReference.encode(v)
      end
    end
  end
end
