require "pathname"

module VagrantPlugins
  module GPIICi

    lib_path = Pathname.new(File.expand_path("../vagrant-gpii-ci", __FILE__))
    autoload :Action, lib_path.join("action")
    autoload :Errors, lib_path.join("errors")

    # This returns the path to the source of this plugin.
    #
    # @return [Pathname]
    def self.source_root
      @source_root ||= Pathname.new(File.expand_path("../../", __FILE__))
    end
  end
end

begin
  require "vagrant"
rescue LoadError
  raise "The Vagrant GPII CI plugin must be run within Vagrant."
end

# This is a sanity check to make sure no one is attempting to install
# this into an early Vagrant version.
if Vagrant::VERSION < "1.8.0"
  raise "The Vagrant GPII CI plugin is only compatible with Vagrant 1.8+"
end

require "vagrant-gpii-ci/plugin"