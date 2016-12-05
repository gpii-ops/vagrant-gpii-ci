Vagrant-vmenv
=============

Vagrant-vmenv is a npm module that is used to extend the behavior of a
Vagrantfile. It uses virtual machine definitions to spin up complete
enviroments where you can run tests or run your code.

Installation
------------

```
npm install -g http://github.com/amatas/vagrant-vmenv
cp node_modules/vagrant-vmenv/Vagrantfile.template Vagrantfile
cp node_modules/vagrant-vmenv/qi.yml.template .qi.yml
```

The Vagrantfile acts as a pointer to the module, it shouldn't be modified. If
you want to make a change at the environment level do so in the [environment
configuration file](envs/), and if you want to configure how the applications
are deployed and tested do so in the [.qi.yml](qi.yml.template) file of your
repository.

Working with vms
----------------

Commands:

 * `vagrant up` to spin up the [environment](envs/) defined in the .qi.yml file.
 * `vagrant destroy` to stop and destroy the vm.
 * `vagrant halt` to shutdown the vm without destroy it.

Note:

 * `vagrant up` will exec the commands listed in the *setup* variable of each
application listed in the .qi.yml file.
 * `vagrant provision` will exec the commands listed in the *test_cmds* variable
of each application listed in the .qi.yml file.

Networking
----------

A VM can have multiple virtual NICs. Two types are avilable for each NIC: public
and private. The public NICs will be attached to the host's physical network,
the private NICs will be attached to a private network only visible between the
other VMs and the host. The IP address of a private network can be customized in
the definition of the VM. An example of the network definition of a VM can be:

```
networks:
  privatenet:
    type: private
    ip: 192.168.45.22
  publicnet:
    type: public
```

If an environment has multiple VMs definitions with several NICs the *hosts*
file of each VM will list all the IP address of each VM plus the name of the VM,
this is very useful to point services between the VMs.

Forwarded ports
---------------

The port forwarding is configured in the VMs definition. The `guest_port`
variable is the source port to be mapped to the `host_port` variable. The
`guest_port` must be set in each port forward block, `host_port` and protocol are
optionals.

```
ports:
  - guest_port: 8080
    host_port: 8888
    protocol: tcp
  - guest_port: 8181
    host_port: 9999
  - guest_port:8081
```

Shared folders
--------------

Each application can use a shared folder. If the *folder* variable of the
application has a *src* key, Vagrant will map the path set in the src folder of
the host to the path set in the *dest* variable in the VM.

```
folder:
  src: "."
  dest: "/app/universal"
```

More samples definitions can be found either in the [envs](envs) directory or in
the [qi.yml.template](qi.yml.template).

