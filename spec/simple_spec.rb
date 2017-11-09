describe "Current failures" do
  it "is failing" do
    Bundler.with_clean_env do
      ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
        rc, msg = MiqAeEngine::MiqAeMethod.send(:run_method, Gem.ruby) { |stdin| stdin.puts(the_script)}
        puts "XXX MSG #{msg}"
        expect(rc).to eq(0)
      end
    end
  end

  def the_script
    <<-SCRIPT
    require 'date'
    require 'rubygems'
    $:.unshift("#{Gem.loaded_specs['activesupport'].full_gem_path}/lib")
    require 'active_support/all'
    require 'socket'
    Socket.do_not_reverse_lookup = true  # turn off reverse DNS resolution

    require 'drb'
    require 'yaml'
  SCRIPT
  end
end
