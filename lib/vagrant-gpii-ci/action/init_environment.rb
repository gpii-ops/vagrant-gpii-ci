require "log4r"

module VagrantPlugins
  module GPIICi
    module Command
      # This action sets up the GPII CI environment
      class InitEnvironment < Vagrant.plugin("2", :command)

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("VagrantPlugins::GPIICi::action::init_environment")
        end

        def call(env)
          @logger.info('This call does nothing yet')
          #TODO: Create a .vagrant.yml file based on a template
          @app.call(env)
        end

      end
    end
  end
end
