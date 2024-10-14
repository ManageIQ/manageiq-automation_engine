module MiqAeEngine
  class MiqAeDomainSearch
    def initialize
    end

    def ae_user=(obj)
      @ae_user = obj
    end

    def get_alternate_domain(scheme, uri, namespace, klass, instance)
      return namespace if namespace.nil? || klass.nil?
      return namespace if scheme != "miqaedb"

      search(uri, namespace, klass, instance, nil)
    end

    def get_alternate_domain_method(scheme, uri, namespace, klass, method)
      return namespace if namespace.nil? || klass.nil?
      return namespace if scheme != "miqaedb"

      search(uri, namespace, klass, nil, method)
    end

    private

    def search(uri, namespace, klass, instance, method)
      updated_ns = find_first_fq_domain(uri, "#{@prepend_namespace}/#{namespace}", klass, instance, method) if @prepend_namespace
      updated_ns ||= find_first_fq_domain(uri, namespace, klass, instance, method)
      updated_ns || namespace
    end

    def find_first_fq_domain(uri, namespace, klass, instance, method)
      matching_ns = get_matching_domain(namespace, klass, instance, method)
      matching_ns ||= get_matching_domain(namespace, klass, MiqAeObject::MISSING_INSTANCE, method)
      $miq_ae_logger.info("Updated namespace [#{ManageIQ::Password.sanitize_string(uri)}  #{matching_ns}]") if matching_ns
      matching_ns
    end

    def get_matching_domain(namespace, klass, instance, method)
      relative_path = instance ? "#{namespace}/#{klass}/#{instance}" : "#{namespace}/#{klass}/#{method}"
      klass = instance ? ::MiqAeInstance : ::MiqAeMethod
      match = klass.find_best_match_by(@ae_user, relative_path)
      match.namespace[1..-1] if match
    end
  end
end
