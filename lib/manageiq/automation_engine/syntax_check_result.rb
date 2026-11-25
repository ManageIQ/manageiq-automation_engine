module ManageIQ
  module AutomationEngine
    class SyntaxCheckResult
      # All of the syntax errors found, as an array of [line, text] pairs
      attr_reader :errors

      def initialize(parse_result)
        @valid = parse_result.success?
        @errors = valid? ? [] : parse_result.errors.map { |e| [e.location.start_line, e.message] }
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
    end
  end
end
