if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

require 'manageiq-automation_engine'

Dir[ManageIQ::AutomationEngine::Engine.root.join("spec/support/**/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/shared/**/*.rb")].each { |f| require f }
