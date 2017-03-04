Vagrant-GPII-CI
=============

Scope
-----

Vagrant-GPII-CI is a vagrant plugin that is used to simplify the definition of a Vagrantfile. It uses virtual machine and scripts definitions to spin up complete enviroments where you can run your tests or applications.

Installation
------------

The installation is as simple as run this command in your user's shell:

```
vagrant plugin install vagrant-gpii-ci
```

Working with vms
----------------

No Vagrantfile is required if a file [.gpii-ci.yml](gpii-ci.yml.template) is found in the root of the repository.

The name of the file can be override using the environment variable `VAGRANT_CI_FILE`.

Commands:

 * `vagrant up [vm]` to spin up the vms defined in the .ci_env variable. 
 * `vagrant destroy [vm]` to stop and destroy the vm.
 * `vagrant reload [vm]` to stop and destroy the vm.
 * `vagrant halt [vm]` to shutdown the vm without destroy it.
 * `vagrant ci test [vm]` to run all the stages defined in the .ci_stages variable, at the selected vm.

Note:

 * The `vm` parameter is not necessary in environments with only one VM defined.


Virtual Machines definition
---------------------------

The `.ci_env` variable must have a child variable called `vms` that lists the names of the virtual machines defined. Each name of a VM must have some additional options.

The options available for a vm definition are:

 * `3d` - Enable 3D support. _False_ by default.
 * `autostart - Starts the vm when the command `up` is executed. _True_ by default.
 * `box` - Defines the base box that the vm will use. `Required`
 * `clone` - Use the [Vagrant clone feature](https://www.vagrantup.com/docs/virtualbox/configuration.html#linked-clones) to make the creation of the vm faster. _False_ by default.
 * `cpu` - Defines the number of the virtual CPUs. `Required`
 * `memory` - Defines the amount of RAM memory assigned to the VM. `Required`
 * `sound` - Enables a dummy sound card in the VM. Disabled by default
 * `gui` - Enable the GUI of the VM. _True_ by default.

Samples
=======

```
.ci_env:
  vms:
    windows10:
      cpu: 2
      memory: 2048
      clone: true
      autostart: true
      box: inclusivedesign/windows10-eval
```

In the following example we use the [merge](http://yaml.org/type/merge.html) feature of YAML to simplify the virtual machines definitions.

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

All the VMs have access to Internet using the gateway of the host through a NAT interface by default.

In the case of multi VM environments, a additional NIC card is create in each VM with a private IP address of a private network where all the VMs are connected. The IP range of this network is 192.168.50.0/24. The IP addresses assigned to each VM start by 10 and is incremented by 1 in additional VMs.

Mapped ports
---------------

The port mapping is configured in the VMs definition. The `mapped_ports` variable is a list of ports that will be mapped from the VM to the host.

```
mapped_ports:
  - 8080
  - 8181
```

Tags
----

The tags can be used to run specific stages in some VMs. A stage with a set of tags will be only executed in the VMs that have those tags listed. If a stage doesn't have tags defined it will be executed in all VMs.

Sample
=======

```
.ci_env:
  default: &default
    cpu: 2                 # number of cpus
    memory: 2048           # amount of RAM memory
    clone: true            # use the linked_clone Vagrant feature
    autostart: false       # only start a VM when it's specfied in the command line
  vms:
    windows:               # name of the VM
      <<: *default         # referece of the common part
      tags:
        - windows
      box: inclusivedesign/windows
    fedora:                # name of the VM
      <<: *default         # referece of the common part
      tags:
        - linux
      box: inclusivedesign/fedora

.ci_stages:                # Stages to perform when 'ci test' command is invoked
  - setup_win
  - setup_linux
  - test

setup_win_job:
  stage: setup_win         # name of the stage
  tags:                    # This stage will be only executed on Windows VMs
    - windows
  script:
    - |
      choco upgrade firefox googlechrome -y
      choco install -y nodejs python2 msbuild.extensionpack microsoft-build-tools
      refreshenv
    - |
      npm config -g set msvs_version 2015
      npm install -g testem node-gyp
      refreshenv
    - |
      npm install
      refreshenv
    - testem ci -l firefox
    - testem ci -l chrome

setup_linux_job:
  stage: setup_linux       # name of the stage
  tags:                    # This stage will be only executed on linux VMs
    - linux
  script:
    - sudo ansible-galaxy install -fr provisioning/requirements.yml
    - |
      sudo mkdir -p /var/tmp/vagrant/node_modules /vagrant/node_modules
      sudo chown vagrant:vagrant -R /var/tmp/vagrant/node_modules /vagrant/node_modules
      sudo mount -o bind /var/tmp/vagrant/node_modules /vagrant/node_modules

test_job:
  stage: test
  script:
    - npm run node-test
    - npm run browser-test

```