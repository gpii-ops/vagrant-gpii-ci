require 'optparse'

require_relative "base"

module VagrantPlugins
  module Cienv
    module Command
      class InitEnvironment < Base
        def execute
          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant qi init [-h]"
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv
          raise Vagrant::Errors::CLIInvalidUsage, help: opts.help.chomp if argv.length > 0

          # List the installed plugins
          action(Action.action_init)

          # Success, exit status 0
          0
        end
      end
    end
  end
end
