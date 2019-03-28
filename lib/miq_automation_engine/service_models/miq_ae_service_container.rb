module MiqAeMethodService
  class MiqAeServiceContainer < MiqAeServiceModelBase
    expose :metrics
    expose :metric_rollups
    expose :vim_performance_states

    expose :is_tagged_with?
    expose :tags
  end
end
