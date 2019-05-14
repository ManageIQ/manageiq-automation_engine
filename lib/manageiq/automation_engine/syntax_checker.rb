require "open3"

module ManageIQ
  module AutomationEngine
    class SyntaxChecker
      def self.check(ruby)
        Open3.popen3 "ruby -wc" do |stdin, stdout, stderr|
          stdin.write ruby
          stdin.close
          output = stdout.read
          errors = stderr.read
          SyntaxCheckResult.new(output && !output.empty? ? output : errors)
        end
      end
    end
  end
end
