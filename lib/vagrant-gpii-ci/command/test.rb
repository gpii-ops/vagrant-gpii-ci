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
            o.banner = "Usage: vagrant gpii-ci test [options] [name|id]"
            o.separator ""
            o.separator "Options:"
            o.separator ""
  
            o.on("-a", "--auto", "Execute an SSH command directly") do |c|
              options[:auto] = true
            end
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
          if [:stderr, :stdout].include?(type)
            # Output the data with the proper color based on the stream.
            color = type == :stdout ? :green : :red
  
            # Clear out the newline since we add one
            data = data.chomp

            return if data.empty?
  
            options = {}
            options[:color] = color 
            #if type.eql?(:stderr) and !data.empty?
            #  doc = REXML::Document.new(data)
            #  formatter = REXML::Formatters::Pretty.new
            #  
            #  # Compact uses as little whitespace as possible
            #  formatter.compact = true
            #  formatter.write(doc, data)
            #end
            machine.ui.info(data, options)
          end
        end
      end
    end
  end
end