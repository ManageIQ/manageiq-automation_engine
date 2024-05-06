module MiqAeMethodService
  class MiqAeServiceAutomationTask < MiqAeServiceMiqRequestTask
    expose :automation_request, :association => true
    expose :statemachine_task_status
  end
end
