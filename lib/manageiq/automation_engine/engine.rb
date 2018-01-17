require 'rails/engine'

module ManageIQ
  module AutomationEngine
    class Engine < ::Rails::Engine
      isolate_namespace ManageIQ::AutomationEngine

      config.autoload_paths << root.join("app/models/mixins").to_s
      config.autoload_paths << root.join("lib/miq_automation_engine").to_s
      config.autoload_paths << root.join("lib/miq_automation_engine/engine").to_s

      def vmdb_plugin?
        true
      end
    end
  end
end
