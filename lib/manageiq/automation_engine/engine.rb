require 'rails/engine'

module ManageIQ
  module AutomationEngine
    class Engine < ::Rails::Engine
      isolate_namespace ManageIQ::AutomationEngine

      # NOTE:  If you are going to make changes to autoload_paths, please make
      # sure they are all strings.  Rails will push these paths into the
      # $LOAD_PATH.
      #
      # More info can be found in the ruby-lang bug:
      #
      #   https://bugs.ruby-lang.org/issues/14372
      #
      config.autoload_paths << root.join("app/models/mixins").to_s
      config.autoload_paths << root.join("lib/miq_automation_engine").to_s
      config.autoload_paths << root.join("lib/miq_automation_engine/engine").to_s

      def vmdb_plugin?
        true
      end
    end
  end
end
