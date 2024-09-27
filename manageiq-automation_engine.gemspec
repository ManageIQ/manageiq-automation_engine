# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'manageiq/automation_engine/version'

Gem::Specification.new do |spec|
  spec.name          = "manageiq-automation_engine"
  spec.version       = ManageIQ::AutomationEngine::VERSION
  spec.authors       = ["ManageIQ Authors"]

  spec.summary       = "Automation Engine plugin for ManageIQ."
  spec.description   = "Automation Engine plugin for ManageIQ."
  spec.homepage      = "https://github.com/ManageIQ/manageiq-automation_engine"
  spec.license       = "Apache-2.0"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rubyzip", "~>2.0.0"
  spec.add_dependency "drb"

  spec.add_development_dependency "manageiq-style"
  spec.add_development_dependency "simplecov", ">= 0.21.2"
end
