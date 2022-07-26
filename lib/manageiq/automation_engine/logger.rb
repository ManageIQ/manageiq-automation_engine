module ManageIQ
  module AutomationEngine
    class Logger < ManageIQ::Loggers::Base
      def add(severity, message = nil, progname = nil, resource_id: nil)
        # Copied from Logger#add
        severity ||= UNKNOWN
        if @logdev.nil? or severity < level
          return true
        end
        if progname.nil?
          progname = @progname
        end
        if message.nil?
          if block_given?
            message = yield
          else
            message = progname
            progname = @progname
          end
        end

        RequestLog.create(:message => message, :severity => format_severity(severity), :resource_id => resource_id) if resource_id

        super(severity, message, progname)
      end

      def info(progname = nil, resource_id: nil, &block)
        add(INFO, nil, progname, resource_id: resource_id, &block)
      end

      def debug(progname = nil, resource_id: nil, &block)
        add(DEBUG, nil, progname, resource_id: resource_id, &block)
      end

      def warn(progname = nil, resource_id: nil, &block)
        add(WARN, nil, progname, resource_id: resource_id, &block)
      end

      def error(progname = nil, resource_id: nil, &block)
        add(ERROR, nil, progname, resource_id: resource_id, &block)
      end

      def fatal(progname = nil, resource_id: nil, &block)
        add(FATAL, nil, progname, resource_id: resource_id, &block)
      end

      def unknown(progname = nil, resource_id: nil, &block)
        add(UNKNOWN, nil, progname, resource_id: resource_id, &block)
      end
    end
  end
end
