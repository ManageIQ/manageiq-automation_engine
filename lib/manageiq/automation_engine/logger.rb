module ManageIQ
  module AutomationEngine
    class Logger < ManageIQ::Loggers::Base
      attr_reader :automation_log_wrapper, :resource_id

      def initialize(*args, automation_log_wrapper:, resource_id: nil, **kwargs)
        @automation_log_wrapper = automation_log_wrapper
        @resource_id            = resource_id

        super(*args, **kwargs)
      end

      def self.create_log_wrapper(io: File::NULL, automation_log_wrapper: nil, resource_id: nil)
        # We modify the interface of logger methods such as info/warn/etc. to allow the keyword argument
        # resource_id. Therefore, we need to wrap all client logger calls to these methods to process the resource_id,
        # cut the request_log entry and forward the remaining arguments to the logger.
        new(io, :progname => "automation", :automation_log_wrapper => automation_log_wrapper || Vmdb::Loggers.create_logger("automation.log"), :resource_id => resource_id)
      end

      private

      def add(severity, message = nil, progname = nil, &block)
        automation_log_wrapper.add(severity, message, progname, &block)

        severity ||= Logger::UNKNOWN
        return true if severity < @level

        progname ||= @progname

        if message.nil?
          if block_given?
            message = yield
          else
            message = progname
            progname = @progname
          end
        end

        RequestLog.create(:message => message, :severity => format_severity(severity), :resource_id => resource_id) if resource_id

        super
      end
    end
  end
end
