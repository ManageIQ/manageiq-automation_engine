module ManageIQ
  module AutomationEngine
    class SyntaxChecker
      def self.check(ruby)
        require "prism"

        SyntaxCheckResult.new(Prism.parse(ruby))
      end
    end
  end
end
