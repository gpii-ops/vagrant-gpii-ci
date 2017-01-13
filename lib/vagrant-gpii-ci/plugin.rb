begin
  require "vagrant"
  #require 'vagrant-gpii-ci/action'
rescue LoadError
  raise "The Vagrant GPII CI plugin must be run within Vagrant."
end

module VagrantPlugins
  module GPIICi
    class Plugin < Vagrant.plugin("2")
      name "GPIICi"
      description <<-DESC
      Vagrant plugin that parses a definition file in YAML to spin up
      VMs to recreate an environment and run some tests.
      DESC

      action_hook(:build_config, :environment_load) do |hook|
        hook.prepend(Action.build_vagrantfile)
      end

      command("test") do
         require File.expand_path("../command/test", __FILE__)
         Command::Test
      end

      # This sets up our log level to be whatever VAGRANT_LOG is.
      def self.setup_logging
        require "log4r"

        level = nil
        begin
          level = Log4r.const_get(ENV["VAGRANT_LOG"].upcase)
        rescue NameError
          # This means that the logging constant wasn't found,
          # which is fine. We just keep `level` as `nil`. But
          # we tell the user.
          level = nil
        end

        # Some constants, such as "true" resolve to booleans, so the
        # above error checking doesn't catch it. This will check to make
        # sure that the log level is an integer, as Log4r requires.
        level = nil if !level.is_a?(Integer)

        # Set the logging level on all "vagrant" namespaced
        # logs as long as we have a valid level.
        if level
          logger = Log4r::Logger.new("vagrant_cienv")
          logger.outputters = Log4r::Outputter.stderr
          logger.level = level
          logger = nil
        end
      end
    end
  end
end


