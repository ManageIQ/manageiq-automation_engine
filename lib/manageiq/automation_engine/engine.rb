require 'rails/all'

module ManageIQ
  module AutomationEngine
    class Engine < ::Rails::Engine
      isolate_namespace ManageIQ::AutomationEngine

      config.autoload_paths << root.join("app/models/mixins")
      config.autoload_paths << root.join("lib/miq_automation_engine")
      config.autoload_paths << root.join("lib/miq_automation_engine/engine")

      def vmdb_plugin?
        true
      end
    end
  end
end
