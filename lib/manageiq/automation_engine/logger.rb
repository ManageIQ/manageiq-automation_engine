module ManageIQ
  module AutomationEngine
    class Logger < Vmdb::Loggers::RequestLogger
      def self.create_log_wrapper(io = File::NULL)
        # We modify the interface of logger methods such as info/warn/etc. to allow the keyword argument
        # resource_id. Therefore, we need to wrap all client logger calls to these methods to process the resource_id,
        # cut the request_log entry and forward the remaining arguments to the logger.
        new(io, :progname => "automation", :log_wrapper => Vmdb::Loggers.create_logger("automation.log"))
      end
    end
  end
end
