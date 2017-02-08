Vagrant-GPII-CI
=============

Vagrant-GPII-CI is a vagrant plugin that is used to simplify the configuration stored in a Vagrantfile. It uses virtual machine definitions to spin up complete
enviroments where you can run tests or run your code.

Installation
------------

```
vagrant plugin install vagrant-gpii-ci
```

Working with vms
----------------

No Vagrantfile is required if a file [.gpii-ci.yml](gpii-ci.yml.template) is found in the root of the repository.

The name of the file can be override using the environment variable `VAGRANT_CI_FILE`.

Commands:

 * `vagrant up [vm]` to spin up the defined in the .ci_env variable of the [.gpii-ci.yml](gpii-ci.yml.template) file. 
 * `vagrant destroy [vm]` to stop and destroy the vm.
 * `vagrant reload [vm]` to stop and destroy the vm.
 * `vagrant halt [vm]` to shutdown the vm without destroy it.
 * `vagrant ci test [vm]` to run all the stages defined in the selected vm


Note:

 * The `vm` parameter is not necessary in environments with only one VM defined.

Sample:


```
.ci_env:
  default: &default
    cpu: 2                   # number of cpus
    memory: 2048             # amount of RAM memory
    clone: true              # use the linked_clone Vagrant feature
    autostart: false         # only start a VM when it's specfied in the command line
  vms:
    windows10:               # name of the VM
      <<: *default           # referece of the common part
      3d: true               # enable 3D acceleration
      sound: true            # add a sound card to the VM
      box: inclusivedesign/windows10-eval
    windows81:               # name of the VM
      <<: *default           # referece of the common part
      box: inclusivedesign/windows81-eval-x64
    windows7:                # name of the VM
      <<: *default           # referece of the common part
      box: inclusivedesign/windows7-eval-x64
```

Networking
----------

All the VMs have access to Internet using the gateway of the host through a NAT interface.

In the case of multi VM environments, a additional NIC card is create in each VM with a private IP of a private network that all the VMs share. The IP range of this network is 192.168.50.0/24. The IP address are assigned to each VM starting by 10.

Mapped ports
---------------

The port mapping is configured in the VMs definition. The `mapped_ports`
variable is a list of ports that will be mapped from the VM to the host.

```
mapped_ports:
  - 8080
  - 8181
```

