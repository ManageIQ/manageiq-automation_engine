module MiqAeEngine
  module MiqAeDeserializeWorkspace
    def update_workspace(hash)
      hash['objects'].each { |path, attrs| update_object(path, attrs, ae_user) }
      hash['state_vars'].each { |k, v| @persist_state_hash[k] = MiqAeReference.decode(v, ae_user) }
    end

    def update_object(path, attributes, user)
      obj = path == "root" ? root : find_object(root, path)
      $miq_ae_logger.error("Object #{path} not found in workspace") unless obj
      raise MiqAeException::Error, "object not found #{path}" unless obj
      update_obj_attributes(obj, attributes, user)
    end

    def update_obj_attributes(obj, updated_attributes, user)
      updated_attributes.each do |name, value|
        obj[name] = MiqAeReference.decode(value, user)
      end
    end

    def find_object(obj, object_name)
      return obj if obj.object_name == object_name
      obj.children.each do |child|
        found = find_object(child, object_name)
        return found if found
      end
      nil
    end
  end
end
