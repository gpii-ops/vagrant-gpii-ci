module VagrantPlugins
  module GPIICi
    module Action
      class BuildVagrantfile

        def initialize(app, env)
          @app = app
        end

        def call(env)
          @env = env

          if File.exist?(project_home(@env).join(".qi.yml")) 
          
            environment = @env[:env]
            ci_definition = get_ci_definition (".qi.yml")
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
          ci_tests["shell"] = {}
          definition.each do |name, content|
            next if name.start_with?(".") or name.eql?("stages")
            if content.include?("stage")
              ci_tests["shell"][content["stage"]] = content["script"]
            end
          end

          ci_tests["stages"] = definition["stages"]
          ci_tests
        end

        def get_ci_definition(definition_file)
          # load the definition file
          ci_file = File.expand_path(project_home(@env).join(definition_file))
          @ci_definition = YAML.load(File.read(ci_file))
        end

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
          ci_environment_vms = inject_private_network_config(definition[".ci_env"]["vms"])
          #TODO: load additional yaml files to extend the definition
        end

        # Setup the provider using the definition of each VM.
        def set_provider_config(vm_instance, ci_vm_definition)
      
          vm_instance.vm.provider :virtualbox do |vm|
      
            vm.linked_clone = ci_vm_definition["clone"] || false
            
            vm.customize ["modifyvm", :id, "--memory", ci_vm_definition["memory"] ]
            vm.customize ["modifyvm", :id, "--cpus", ci_vm_definition["cpu"] ]
      
            if ci_vm_definition["3d"] == true then
              vm.customize ["modifyvm", :id, "--vram", "128"]
              vm.customize ["modifyvm", :id, "--accelerate3d", "on"]
            end
            
            if ci_vm_definition["sound"] == true then
              vm.customize ["modifyvm", :id, "--audio", "null", "--audiocontroller", "ac97"]
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

        def define_vm(vagrant_config, ci_vm_id, ci_vm_definition)
          vagrant_config.vm.define ci_vm_id, autostart: ci_vm_definition["autostart"] || true do |vm_instance|
                vm_instance.vm.hostname = ci_vm_id
                set_provider_config(vm_instance, ci_vm_definition)
                set_network_config(vm_instance, ci_vm_definition)
          end
        end

        def build_vms_config(vagrant_config, ci_environment_vms)
          ci_environment_vms.each do |ci_vm_id, ci_vm_definition|
            define_vm(vagrant_config, ci_vm_id, ci_vm_definition)
          end
        end
      end
    end
  end
end     