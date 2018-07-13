module MiqAeEngine
  class MiqAeBuiltinMethod
    module MiqAeTaskBuiltin
      extend ActiveSupport::Concern

      module ClassMethods
        def miq_check_provisioned(obj, inputs = {})
          root = obj.workspace.root
          task = root['miq_provision']
          raise ArgumentError, "miq_provision not specified" unless task

          result = task.statemachine_task_status
          $miq_ae_logger.info("Builtin check_provisioned returned <#{result}> for state <#{task.state}> and status <#{task['status']}>")

          set_ae_result(result, task, root, inputs)
        end

        def set_ae_result(result, task, root, inputs)
          case result
          when 'error'
            root['ae_result'] = 'error'
            reason = task.message
            $miq_ae_logger.error("Builtin check_provisioned error <#{reason}>")
            reason = reason[7..-1] if reason[0..6] == 'Error: '
            root['ae_reason'] = reason
          when 'retry'
            root['ae_result']         = 'retry'
            root['ae_retry_interval'] = inputs['ae_retry_interval'] || '1.minute'
          when 'ok'
            root['ae_result'] = 'ok'
          end
        end
      end
    end
  end
end
