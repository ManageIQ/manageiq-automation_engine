require 'rails/all'

module ManageIQ
  module AutomationEngine
    class Engine < ::Rails::Engine
      isolate_namespace ManageIQ::AutomationEngine

      def vmdb_plugin?
        true
      end
    end
  end
end
