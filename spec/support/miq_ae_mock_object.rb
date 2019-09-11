module Spec
  module Support
    class MiqAeMockObject
      attr_reader :children
      attr_accessor :instance, :klass, :namespace, :parent

      def initialize(hash = {})
        @object_hash = HashWithIndifferentAccess.new(hash)
        @children = []
      end

      def attributes
        @object_hash
      end

      def [](attr)
        @object_hash[attr.downcase]
      end

      def []=(attr, value)
        @object_hash[attr.downcase] = value
      end

      def link_parent_child(parent, child)
        parent.children << child
        child.parent = parent
      end

      def object_name
        if namespace && klass && instance
          ::MiqAeEngine::MiqAePath.new(:ae_namespace => namespace,
                                       :ae_class     => klass,
                                       :ae_instance  => instance).to_s
        else
          "root"
        end
      end
    end
  end
end
