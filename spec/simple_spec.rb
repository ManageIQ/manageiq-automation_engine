describe "Current failures" do
  it "is failing" do
    Bundler.with_clean_env do
      ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
        expect { the_script }.not_to raise_error
      end
    end
  end

  def the_script
    require 'date'
    require 'rubygems'
    $:.unshift("#{Gem.loaded_specs['activesupport'].full_gem_path}/lib")
    require 'active_support/all'
    require 'socket'
    Socket.do_not_reverse_lookup = true  # turn off reverse DNS resolution

    require 'drb'
    require 'yaml'
  end
end
