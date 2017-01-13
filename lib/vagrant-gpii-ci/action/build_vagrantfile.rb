module VagrantPlugins
  module GPIICi
    module Action
      class BuildVagrantfile
        def gem_path
          Pathname.new(File.dirname __dir__)
        end
        def project_home
          environment = @env[:env]
          environment.instance_variable_get(:@cwd)  
        end
        def vagrant_home
          project_home.join(Vagrant::Environment::DEFAULT_LOCAL_DATA)
        end
        def initialize(app, env)
          @app = app
        end
        def call(env)
          @env = env
          environment = @env[:env]
          # Only make all the magic if the .qi.yml definition file is found
          return if !File.exist?(project_home.join(".qi.yml")) 
          require_relative "../config/config_provider.rb"
          require_relative "../config/config_provision.rb"
          require_relative "../config/config_network.rb"
          require_relative "../config/config_folders.rb"
          
          # load the .qi.yml file
          qi_file = File.expand_path (project_home.join(".qi.yml"))
          qi_definition = YAML.load(File.read(qi_file))
          # Copy environments and playbooks to home dir if needed
          FileUtils.mkdir(vagrant_home) if !File.exist?(vagrant_home)
          FileUtils.mkdir(vagrant_home.join('provision-ci')) if !File.exist?(vagrant_home.join('provision-ci'))
          FileUtils.cp_r(gem_path.join('envs'), vagrant_home.join('provision-ci/envs')) if !File.exist?(vagrant_home.join('provision-ci/envs'))
          FileUtils.cp_r(gem_path.join('provisioning'), vagrant_home.join('provision-ci/provisioning')) if !File.exist?(vagrant_home.join('provision-ci/provisioning'))
          # load the environment based on "env_runtime" variable of .qi.yml
          vagrant_env = qi_definition["env_runtime"] || "default"
          environment_file = File.expand_path(vagrant_home.to_s + "/provision-ci/envs", File.dirname(__FILE__)) +
                             File::SEPARATOR + vagrant_env
          if File.exists?(environment_file + ".json")
            environment_ci = JSON.parse(File.read(environment_file + ".json"))
          elsif File.exists?(environment_file + ".yml")
            environment_ci = YAML.load(File.read(environment_file + ".yml"))
          else
            raise "Environment_ci config file not found, see envs directory\n #{environment_file}"
          end
          # build the host list of the VMs used, very useful to allow the communication
          # between them based on the hostname and IP stored in the hosts file
          build_hosts_list(environment_ci["vms"])
          vagrantfile_proc = Proc.new do
            Vagrant.configure(2) do |config|
              environment_ci["vms"].each do |vm_id, vm_config|
                config.vm.define vm_id, autostart: vm_config["autostart"] do |instance|
                  # Ansible handles this task better than Vagrant
                  #instance.vm.hostname = vm_id
                  config_provider(instance, vm_config, environment_ci["global"])
                  config_provision(instance, vm_config, vm_id, qi_definition["apps"], vagrant_home.join('provision-ci').to_s)
                  config_network(instance, vm_config)
                  config_folders(instance, vm_id, qi_definition["apps"], vagrant_home.join('provision-ci').to_s)
                end
              end
            end 
          end
          # The Environment instance has been instantiated without a Vagrantfile
          # that means that we need to store some internal variables and 
          # instantiate again the Vagrantfile instance with our previous code.
          environment.instance_variable_set(:@root_path, project_home)
          environment.instance_variable_set(:@local_data_path, vagrant_home) 
          # the cienv code will be the first item to check in the list of
          # Vagrantfile sources
          config_loader = environment.config_loader
          config_loader.set(:cienv, vagrantfile_proc.call)
          environment.instance_variable_set(:@vagrantfile, Vagrant::Vagrantfile.new(config_loader, [:cienv, :home, :root]))
          @app.call(env)
        end
      end
    end
  end
end     