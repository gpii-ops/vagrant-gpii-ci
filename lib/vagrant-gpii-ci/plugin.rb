begin
  require "vagrant"
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

      # Register capability to run commmands

      # Create an action_hook to run the commands at the end of the provision

      # run the test jobs when "test" command is invoked using the capability
      command("ci") do
         require File.expand_path("../command/ci", __FILE__)
         Command::Ci
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
          logger = Log4r::Logger.new("vagrant_gpii_ci")
          logger.outputters = Log4r::Outputter.stderr
          logger.level = level
          logger = nil
        end
      end
    end
  end
end


