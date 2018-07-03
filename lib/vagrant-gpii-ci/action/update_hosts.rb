module VagrantPlugins
  module GPIICi
    module Action
      class UpdateHosts

        def initialize(app, env)
          @global_env = global_env
          @config = Util.get_config(@global_env)
          @provider = provider
          @logger = Log4r::Logger.new('vagrant::hostmanager::updater')
          @logger.debug("init updater")
        end

        def update_guest(machine)
          return unless machine.communicate.ready?

          if machine.config.vm.communicator == :winrm
            windir = ""
            machine.communicate.execute("echo %SYSTEMROOT%", {:shell => :cmd}) do |type, contents|
              windir << contents.gsub("\r\n", '') if type == :stdout
            end
            realhostfile = "#{windir}\\System32\\drivers\\etc\\hosts.tmp"
          else
            realhostfile = '/tmp/hosts'
          end
          # download and modify file with Vagrant-managed entries
          file = @global_env.tmp_path.join("hosts.#{machine.name}")
          machine.communicate.download(realhostfile, file)

          @logger.debug("file is: #{file.to_s}")
          @logger.debug("class of file is: #{file.class}")

          if update_file(file, machine, false)
            if windir
              machine.communicate.sudo("mv -force /tmp/hosts/hosts.#{machine.name} #{realhostfile}")
            else
              machine.communicate.sudo("cat /tmp/hosts >> #{realhostfile}")
            end
          end

        end

        private

        def update_file(file, resolving_machine = nil, include_id = true)
          file = Pathname.new(file)
          old_file_content = file.read
          new_file_content = update_content(old_file_content, resolving_machine, include_id)
          file.open('wb') { |io| io.write(new_file_content) }
          old_file_content != new_file_content
        end

        def update_content(file_content, resolving_machine, include_id)
          id = include_id ? " id: #{read_or_create_id}" : ""
          header = "## vagrant-hostmanager-start#{id}\n"
          footer = "## vagrant-hostmanager-end\n"
          body = get_machines
            .map { |machine| get_hosts_file_entry(machine, resolving_machine) }
            .join
          get_new_content(header, footer, body, file_content)
        end

        def get_hosts_file_entry(machine, resolving_machine)
          ip = get_ip_address(machine, resolving_machine)
          host = machine.config.vm.hostname || machine.name
          aliases = machine.config.hostmanager.aliases
          if ip != nil
            "#{ip}\t#{host}\n" + aliases.map{|a| "#{ip}\t#{a}"}.join("\n") + "\n"
          end
        end

        def get_ip_address(machine, resolving_machine)
          custom_ip_resolver = machine.config.hostmanager.ip_resolver
          if custom_ip_resolver
            custom_ip_resolver.call(machine, resolving_machine)
          else
            ip = nil
            if machine.config.hostmanager.ignore_private_ip != true
              machine.config.vm.networks.each do |network|
                key, options = network[0], network[1]
                ip = options[:ip] if key == :private_network
                break if ip
              end
            end
            ip || (machine.ssh_info ? machine.ssh_info[:host] : nil)
          end
        end

        def get_machines
          if @config.hostmanager.include_offline?
            machines = @global_env.machine_names
          else
            machines = @global_env.active_machines
              .select { |name, provider| provider == @provider }
              .collect { |name, provider| name }
          end
          # Collect only machines that exist for the current provider
          machines.collect do |name|
                begin
                  machine = @global_env.machine(name, @provider)
                rescue Vagrant::Errors::MachineNotFound
                  # ignore
                end
                machine
              end
            .reject(&:nil?)
        end

        def get_new_content(header, footer, body, old_content)
          if body.empty?
            block = "\n"
          else
            block = "\n\n" + header + body + footer + "\n"
          end
          # Pattern for finding existing block
          header_pattern = Regexp.quote(header)
          footer_pattern = Regexp.quote(footer)
          pattern = Regexp.new("\n*#{header_pattern}.*?#{footer_pattern}\n*", Regexp::MULTILINE)
          # Replace existing block or append
          old_content.match(pattern) ? old_content.sub(pattern, block) : old_content.rstrip + block
        end

        def read_or_create_id
          file = Pathname.new("#{@global_env.local_data_path}/hostmanager/id")
          if (file.file?)
            id = file.read.strip
          else
            id = SecureRandom.uuid
            file.dirname.mkpath
            file.open('w') { |io| io.write(id) }
          end
          id
        end
      end
    end
  end
end

