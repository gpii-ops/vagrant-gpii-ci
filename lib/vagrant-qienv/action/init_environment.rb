require "log4r"

module VagrantPlugins
  module Cienv
    module Action

      # This action sets up the QI QI environment
      class InitEnvironment

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_qi::action::init_environment")
        end

        def call(env)
          puts "i am inside class InitEnvironment"
          @logger.info('i am inside class InitEnvironment - call()')
          @app.call(env)
        end

      end
    end
  end
end
