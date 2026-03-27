module ManageIQ
  module AutomationEngine
    class Engine < ::Rails::Engine
      isolate_namespace ManageIQ::AutomationEngine

      config.autoload_paths << root.join("app/models/mixins")
      config.autoload_paths << root.join('lib')
      config.autoload_paths << root.join("lib/miq_automation_engine")
      config.autoload_paths << root.join("lib/miq_automation_engine/engine")

      def self.vmdb_plugin?
        true
      end

      def self.plugin_name
        _('Automation Engine')
      end

      def self.init_loggers
        $miq_ae_logger ||= Vmdb::Loggers.create_logger("automation.log")
      end

      def self.apply_logger_config(config)
        Vmdb::Loggers.apply_config_value(config, $miq_ae_logger, :level_automation)
      end
    end
  end
end
