module ManageIQ
  module AutomationEngine
    class Engine < ::Rails::Engine
      isolate_namespace ManageIQ::AutomationEngine

      config.autoload_paths << root.join("app/models/mixins").to_s
      config.autoload_paths << root.join('lib').to_s
      config.autoload_paths << root.join("lib/miq_automation_engine").to_s
      config.autoload_paths << root.join("lib/miq_automation_engine/engine").to_s

      def self.vmdb_plugin?
        true
      end

      def self.plugin_name
        _('Automation Engine')
      end
    end
  end
end
