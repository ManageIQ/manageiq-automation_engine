module MiqAeServiceCustomAttributeMixin
  extend ActiveSupport::Concern

  included do
    expose :migration_status,       :method => :migration_status
    expose :set_migration_status,   :method => :set_migration_status
    expose :reset_migration_status, :method => :reset_migration_status
    expose :custom_keys,            :method => :miq_custom_keys
    expose :custom_get,             :method => :miq_custom_get
    expose :custom_set,             :method => :miq_custom_set, :override_return => true
  end
end
