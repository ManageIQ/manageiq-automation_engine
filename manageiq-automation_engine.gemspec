$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "manageiq/automation_engine/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "manageiq-automation_engine"
  s.version     = ManageIQ::AutomationEngine::VERSION
  s.authors     = ["ManageIQ Developers"]
  s.homepage    = "https://github.com/ManageIQ/manageiq-automation_engine"
  s.summary     = "ManageIQ Automation Engine"
  s.description = "ManageIQ Automation Engine"
  s.licenses    = ["Apache-2.0"]

  s.files = Dir["{app,lib}/**/*", "LICENSE.txt", "Rakefile", "README.md"]

  s.add_dependency "rubyzip", "~>1.2.1"

  s.add_development_dependency "codeclimate-test-reporter", "~> 1.0.0"
  s.add_development_dependency "simplecov"
end
