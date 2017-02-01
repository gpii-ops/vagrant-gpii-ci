require "log4r"

module VagrantPlugins
  module GPIICi
    module Command
      # This action sets up the QI QI environment
      class InitEnvironment < Vagrant.plugin("2", :command)

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("VagrantPlugins::GPIICi::action::init_environment")
        end

        def call(env)
          @logger.info('i am inside class InitEnvironment - call()')
          @app.call(env)
        end

      end
    end
  end
end
