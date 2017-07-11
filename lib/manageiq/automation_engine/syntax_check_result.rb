module ManageIQ
  module AutomationEngine
    class SyntaxCheckResult
      attr_reader :error_line, :error_text

      def initialize(output)
        @valid = (output == "Syntax OK\n")
        @output = output
        unless @valid
          match = /^-:(\d+):(.*)/.match(output)
          if match.nil?
            @error_line = 0
            @error_text = output
          else
            @error_line = match[1].to_i
            @error_text = match[2]
          end
        end
      end

      def valid?
        @valid
      end
    end
  end
end
