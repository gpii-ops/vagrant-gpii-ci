require 'yaml'

module VagrantPlugins
  module GPIICi
    module Action
      class BuildVagrantfile

        def initialize(app, env)
          @app = app
        end

        def call(env)
          @env = env

          # The file .gpii-ci.yml can be override using this environment variable
          ci_file ||= ENV["VAGRANT_CI_FILE"] if ENV.key?("VAGRANT_CI_FILE")
          ci_file ||= ".vagrant.yml"

          # Only if the ci_file is found the plugin will run
          if File.exist?(project_home(@env).join(ci_file)) 
          
            environment = @env[:env]
            ci_definition = get_ci_definition (ci_file)
            environment.instance_variable_set(:@ci_tests, get_ci_tests(ci_definition))
            vagrantfile_proc = Proc.new do
              Vagrant.configure(2) do |config|
                build_vms_config(config, get_ci_environment(ci_definition))
              end 
            end

            # The Environment instance has been instantiated without a Vagrantfile
            # that means that we need to store some internal variables and 
            # instantiate again the Vagrantfile instance with our previous code.
            environment.instance_variable_set(:@root_path, project_home(@env))
            environment.instance_variable_set(:@local_data_path, vagrant_home(@env))
            # the cienv code will be the first item to check in the list of
            # Vagrantfile sources
            config_loader = environment.config_loader
            config_loader.set(:cienv, vagrantfile_proc.call)
            environment.instance_variable_set(:@vagrantfile, Vagrant::Vagrantfile.new(config_loader, [:cienv, :home, :root]))

          end
          @app.call(env)
        end

        def vagrant_home(env)
          project_home(env).join(Vagrant::Environment::DEFAULT_LOCAL_DATA)
        end

        def project_home(env)
          environment = env[:env]
          environment.instance_variable_get(:@cwd)  
        end

        def get_ci_tests(definition)
          ci_tests = {}
          if not definition.include?(".ci_env")
            puts "WARNING: .ci_env not declared in the definition file"
            return ci_tests
          elsif not definition.include?(".ci_stages")
            puts "WARNING: .ci_stages not declared in the definition file"
            return ci_tests
          end
          definition[".ci_env"]["vms"].each do | vmname, vmdetails |

            ci_tests["#{vmname}"] = {}
            ci_tests["#{vmname}"]["shell"] = {}
            definition[".ci_stages"].each do |stage|
              definition.each do |stagename, stagecontent|
                # Ignore the statements that start with a dot
                next if stagename.start_with?(".") or stagename.eql?("stages") or not stagecontent["stage"].eql?(stage)
                # Build the hash of tests for each VM
                if stagecontent.include?("stage")
                  if vmdetails.include?("tags") and stagecontent.include?("tags")
                    ci_tests["#{vmname}"]["shell"][stagecontent["stage"]] = stagecontent["script"] \
                      if not (stagecontent["tags"] & vmdetails["tags"]).empty?
                  elsif not stagecontent.include?("tags")
                    ci_tests["#{vmname}"]["shell"][stagecontent["stage"]] = stagecontent["script"]
                  else
                    next
                  end  
                end
              end
            end
          end
          ci_tests
        end

        def get_ci_definition(definition_file)
          # load the definition file
          ci_file = File.expand_path(project_home(@env).join(definition_file))
          @ci_definition = YAML.load(File.read(ci_file))
        end

        # In the case of a multiVM environment, we need to connect the VMs using 
        # a private network
        def inject_private_network_config(ci_environment_vms)
          return ci_environment_vms if ci_environment_vms.count() == 1
          int_id = 10
          ci_environment_vms.each do |vm,config|
            ci_environment_vms[vm]["private_ip"] = "192.168.50." + int_id.to_s
            int_id += 1
          end
          ci_environment_vms
        end
        def get_ci_environment(definition)
          if not definition.include?(".ci_env")
            return {}
          end
          ci_environment_vms = inject_private_network_config(definition[".ci_env"]["vms"])
          #TODO: load additional yaml files to extend the definition of the vms
        end

        # Setup the provider using the definition of each VM.
        def set_provider_config(vm_instance, ci_vm_definition)
      
          vm_instance.vm.provider :virtualbox do |vm|
      
            vm.linked_clone = ci_vm_definition["clone"] || false
            
            vm.customize ["modifyvm", :id, "--memory", ci_vm_definition["memory"] ]
            vm.customize ["modifyvm", :id, "--cpus", ci_vm_definition["cpu"] ]

            vm.customize ["modifyvm", :id, "--vram", "256"]
            if ci_vm_definition["3d"] == true then
              vm.customize ["modifyvm", :id, "--accelerate3d", "on"]
            else
              vm.customize ["modifyvm", :id, "--accelerate3d", "off"]
            end
            
            if ci_vm_definition["sound"] == true then
              vm.customize ["modifyvm", :id, "--audio", "null", "--audiocontroller", "hda"]
            end
      
            vm.customize ["modifyvm", :id, "--ioapic", "on"]
            vm.customize ["setextradata", "global", "GUI/SuppressMessages", "all"]
      
            vm.gui = ci_vm_definition["gui"] || true
          end
      
          vm_instance.vm.box = ci_vm_definition["box"]
        
        end

        def set_network_config(vm_instance, ci_vm_definition)
          vm_instance.vm.network :private_network, ip: ci_vm_definition["private_ip"] if ci_vm_definition["private_ip"]
          ci_vm_definition["mapped_ports"].each do |port|
            vm_instance.vm.network "forwarded_port",
            guest: port,
            host: port,
            protocol: "tcp",
            auto_correct: true
          end if ci_vm_definition["mapped_ports"]
        end

        def build_vms_config(vagrant_config, ci_environment_vms)
          ci_environment_vms.each do |ci_vm_id, ci_vm_definition|

            ci_autostart = true
            ci_autostart = ci_vm_definition["autostart"] if ci_vm_definition.key?("autostart")

            vagrant_config.vm.define ci_vm_id, autostart: ci_autostart do |vm_instance|
                  vm_instance.vm.hostname = ci_vm_id
                  set_provider_config(vm_instance, ci_vm_definition)
                  set_network_config(vm_instance, ci_vm_definition)
            end
          end
        end
      end
    end
  end
end     