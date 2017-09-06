module MiqAeEngine
  module MiqAeReference
    def self.encode(value)
      if value.kind_of?(Array)
        value.map { |v| encode(v) }
      elsif value.kind_of?(Hash)
        value.each_with_object({}) { |(k, v), hash| hash[k] = encode(v) }
      elsif /MiqAeMethodService::/ =~ value.class.to_s
        "vmdb_reference::#{value.href_slug}"
      elsif /MiqAePassword/ =~ value.class.to_s
        "miq_password::#{value}"
      else
        value
      end
    end

    def self.decode(value, user)
      if value.kind_of?(Array)
        value.map { |v| decode(v, user) }
      elsif value.kind_of?(Hash)
        value.each_with_object({}) { |(k, v), hash| hash[k] = decode(v, user) }
      elsif value.kind_of?(String) && /vmdb_reference::(.*)/.match(value)
        obj = Api::Utils.resource_search_by_href_slug($1, user)
        MiqAeMethodService::MiqAeServiceModelBase.wrap_results(obj)
      elsif value.kind_of?(String) && /miq_password::(.*)/.match(value)
        MiqAePassword.new(value)
      else
        value
      end
    end
  end
end
