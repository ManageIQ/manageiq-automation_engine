module MiqAeMethodService
  class MiqAeServiceContainerReplicator < MiqAeServiceModelBase
    expose :metric_zones, :association => true
    expose :is_tagged_with?
    expose :tags
  end
end
