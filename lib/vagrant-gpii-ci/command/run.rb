module VagrantPlugins
  module GPIICi
  	module Command
      class CIRun < Vagrant.plugin("2", :command)

        def self.synopsis
          "Run stages on a machine"
        end

        def execute
          param_options = {}
          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant ci run [options] [name|id]"
            o.on("--stage STAGE", String, "Execute specific stage") do |stage|
              param_options[:stage] = stage
            end
          end
          argv = parse_options(opts)
          return if !argv

          @env.ui.info("Launching stages...")

          ci_tests = @env.instance_variable_get(:@ci_tests)

          with_target_vms(argv, single_target: true) do |machine|
            if machine.config.vm.communicator == :winrm
              cwd = "cd c:\\vagrant"
            else
              cwd = "cd /vagrant"
            end
            ci_tests["#{machine.config.vm.hostname}"].each do | provisioner, stages |

              if provisioner.eql?("shell")
                stages.each do |stagename, stagescripts|
                  next if (param_options.include?(:stage) and not stagename.eql?(param_options[:stage]))
                  stagescripts.each do | script |

                    options = {}
                    options[:color] = :blue
                    @env.ui.info("Running shell script:")
                    @env.ui.info("#{script}",options)

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
          if [:stdout,:stderr].include?(type)
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