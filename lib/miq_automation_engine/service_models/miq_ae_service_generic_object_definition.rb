module MiqAeMethodService
  class MiqAeServiceGenericObjectDefinition < MiqAeServiceModelBase
    expose :generic_objects, :association => true
    expose :property_attributes
    expose :property_associations
    expose :property_methods
    expose :create_object
    expose :find_objects
  end
end
