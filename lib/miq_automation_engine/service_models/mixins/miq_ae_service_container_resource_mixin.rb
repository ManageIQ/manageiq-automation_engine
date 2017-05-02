module MiqAeServiceContainerResourceMixin
  extend ActiveSupport::Concern
  included do
    expose :spec
    expose :spec=
    expose :annotations
    expose :tidy_provider_definition
  end
end
