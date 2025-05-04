module ManageIQ
  module AutomationEngine
    class Logger < ManageIQ::Loggers::Base
      attr_reader :resource_id

      def initialize(*args, resource_id: nil, **kwargs)
        @resource_id = resource_id

        super(*args, **kwargs)
      end

      def self.create_log_wrapper(log_wrapper: nil, resource_id: nil)
        log_wrapper ||= $miq_ae_logger

        new(nil, :progname => "automation", :resource_id => resource_id).wrap(log_wrapper)
      end

      private

      def add(severity, message = nil, progname = nil, &block)
        severity ||= Logger::UNKNOWN
        return true if severity < @level || resource_id.nil?

        progname ||= @progname

        if message.nil?
          if block_given?
            message = yield
          else
            message = progname
            progname = @progname
          end
        end

        RequestLog.create(:message => message, :severity => format_severity(severity), :resource_id => resource_id)

        true
      end
    end
  end
end
