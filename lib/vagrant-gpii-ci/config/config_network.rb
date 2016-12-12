# -*- mode: ruby -*-
# vi: set ft=ruby :

# Builds a file with the list of pairs IP address: hostname which will be read
# by Ansible to setup the hosts file in each VM
# Params:
# +env_vms+: object with the definition of the virtual machines

def build_hosts_list(env_vms)

  int_id = 10

  first = true
  env_vms.each do |vm, vmconfig|
    vmconfig["networks"].each do |name, netcfg|
      if netcfg["type"] == "private" then
        if netcfg['ip'].nil? then
          netcfg['ip'] = "192.168.50." + int_id.to_s
          #add the default IP to the environment definnition
          env_vms[vm]["networks"][name]["ip"] = "192.168.50." + int_id.to_s
          int_id += 1
        end
        if first then
          $base_vars = "vms_hosts={"
          $base_vars << "\"#{netcfg['ip']}\":\"#{vm}\""
          first = false
        elsif
          $base_vars << ",\"#{netcfg['ip']}\":\"#{vm}\""
        end
      end
    end if vmconfig["networks"]
  end
  $base_vars << "}" if $base_vars
end

# Configure the network section of a virtual machine. You can set the type of
# the network, the ip address if needed and a list of forwarded ports.
# Params:
# +instance+: The instance of the VM to configure
# +vm_config+: the definition of the VM. There are to type of networks: private
# - where the IP setting is available, and public - where virtualbox will set
# the interface as an external NIC.

def config_network(instance, vm_config)

  vm_config["networks"].each do |network, config|
    if config["type"] == "private" then
      if config["ip"] then
        instance.vm.network :private_network, ip: config["ip"]
      end
    elsif config["type"] == "public" then
      instance.vm.network :public_network
    end
  end if vm_config["networks"]

  vm_config["ports"].each do |port, config|

    raise "At least the guest port is needed in 'guest_port' variable" \
      if config["guest_port"].nil?

    instance.vm.network "forwarded_port",
      guest: config["guest_port"],
      host: config["host_port"] || config["guest_port"],
      protocol: config["protocol"] || "tcp",
      auto_correct: config["auto_correct"] || true
  end if vm_config["ports"]

end

