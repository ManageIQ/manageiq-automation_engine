module ManageIQ
  module AutomationEngine
    class SyntaxCheckResult
      attr_reader :error_line, :error_text

      def initialize(parse_result)
        @valid = parse_result.success?
        return if @valid

        error = parse_result.errors.first
        @error_line = error.location.start_line
        @error_text = error.message
      end

      def valid?
        @valid
      end
    end
  end
end
