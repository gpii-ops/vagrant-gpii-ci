require 'optparse'

module VagrantPlugins
  module GPIICi
  	module Command
      class CITest < Vagrant.plugin("2", :command)

        def self.synopsis
          "Run tests on a machine"
        end

        def execute
          options = {}
          options[:auto] = false

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant ci test [options] [name|id]"
          end
          argv = parse_options(opts)
          return if !argv

          @env.ui.info("Launching tests...")

          ci_tests = @env.instance_variable_get(:@ci_tests)

          with_target_vms(argv, single_target: true) do |machine|
            if machine.config.vm.communicator == :winrm
              cwd = "cd c:\\vagrant"
            else
              cwd = "cd /vagrant"
            end
            
            ci_tests.each do | provisioner, stages |
              if provisioner.eql?("shell")
                ci_tests["stages"].each do |stage|
                  stages[stage].each do | script |
                    @env.ui.info("Running #{script}")
                    machine.communicate.execute("#{cwd}; #{script}") do |type, data|
                      handle_comm(type, data, machine)
                    end
                  end
                end
              end
            end 
          end
        end

        def handle_comm(type, data, machine)
          if [:stdout].include?(type)
            # Output the data with the proper color based on the stream.
            color = type == :stdout ? :green : :red
  
            # Clear out the newline since we add one
            data = data.chomp

            return if data.empty?
  
            options = {}
            options[:color] = color 

            machine.ui.info(data, options)
          end
        end
      end
    end
  end
end