module ManageIQ
  module AutomationEngine
    class SyntaxCheckResult
      # All of the syntax errors found, as an array of [line, text] pairs, in the order reported by ruby
      attr_reader :errors

      def initialize(output)
        @valid = (output == "Syntax OK\n")
        @output = output
        @errors = valid? ? [] : parse_errors(output)
      end

      def valid?
        @valid
      end

      # The first error, kept for backwards compatibility
      def error_line
        errors.first&.first
      end

      def error_text
        errors.first&.last
      end

      private

      def parse_errors(output)
        errors = output.scan(/^-:(\d+):(.*)/).reject { |_line, text| text.lstrip.start_with?("warning:") }
        errors = errors.map { |line, text| [line.to_i, text] }
        errors.empty? ? [[0, output]] : errors
      end
    end
  end
end
