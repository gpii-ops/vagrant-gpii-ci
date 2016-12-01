# -*- mode: ruby -*-
# vi: set ft=ruby :

def config_provider(instance, vm_config, global_config)

  if global_config["provider"] == "virtualbox" then 

    instance.vm.provider :virtualbox do |vm|

      vm.linked_clone = vm_config["clone"] || global_config["clone"] || false
      
      vm.customize ["modifyvm", :id, "--memory", vm_config["memory"] || global_config["memory"] ]
      vm.customize ["modifyvm", :id, "--cpus", vm_config["cpu"] || global_config["cpu"] ]

      if vm_config["gui"] == true then
        vm.customize ["modifyvm", :id, "--vram", "128"]
        vm.customize ["modifyvm", :id, "--accelerate3d", "on"]
      end
      
      if vm_config["sound"] == true then
        vm.customize ["modifyvm", :id, "--audio", "null", "--audiocontroller", "ac97"]
      end

      vm.customize ["modifyvm", :id, "--ioapic", "on"]
      vm.customize ["setextradata", "global", "GUI/SuppressMessages", "all"]

      vm.gui = vm_config["gui"] || global_config["gui"] || false
    end

    instance.vm.box = vm_config["box"]

  elsif global_config["provider"] == "libvirt" then
      raise "Not supported yet"
  else
      raise "Provider not defined in global configuration" unless global_config.include?('provider')
      raise "Provider #{global_config['provider']} not supported"
  end

end

