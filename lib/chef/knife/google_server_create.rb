# Copyright 2013 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require 'timeout'
require 'chef/knife/google_base'

class Chef
  class Knife
    class GoogleServerCreate < Knife

      include Knife::GoogleBase

      deps do
        require 'google/compute'
        require 'chef/json_compat'
        require 'chef/knife/bootstrap'
        Chef::Knife::Bootstrap.load_deps
      end

      banner "knife google server create NAME -m MACHINE_TYPE -I IMAGE -Z ZONE (options)"

      attr_accessor :initial_sleep_delay
      attr_reader :instance

      option :gce_machine_type,
        :short => "-m MACHINE_TYPE",
        :long => "--gce-machine-type MACHINE_TYPE",
        :description => "The machine type of server (n1-highcpu-2, n1-highcpu-2-d, etc)"

      option :gce_image,
        :short => "-I IMAGE",
        :long => "--gce-image IMAGE",
        :description => "The Image for the server"

      option :gce_image_project_id,
        :long => "--gce-image-project-id IMAGE_PROJECT_ID",
        :description => "The project-id containing the Image (debian-cloud, centos-cloud, etc)",
        :default => ""

      option :gce_zone,
        :short => "-Z ZONE",
        :long => "--gce-zone ZONE",
        :description => "The Zone for this server"

      option :gce_boot_disk_name,
        :long => "--gce-boot-disk-name DISK",
        :description => "Name of persistent boot disk; default is to use the server name",
        :default => ""

      option :gce_boot_disk_size,
        :long => "--gce-boot-disk-size SIZE",
        :description => "Size of the persistent boot disk between 10 and 10000 GB, specified in GB; default is '10' GB",
        :default => "10"

      option :gce_boot_disk_ssd,
        :long => "--[no-]gce-boot-disk-ssd",
        :description => "Use pd-ssd boot disk; default is pd-standard boot disk",
        :boolean => true,
        :default => false

      option :gce_boot_disk_autodelete,
        :long => "--[no-]gce-boot-disk-autodelete",
        :description => "Delete boot disk when instance is being deleted.",
        :boolean => true,
        :default => false

      option :gce_additional_disks,
        :long => "--gce-disk-additional-disks DISKS",
        :short => "-D DISKS",
        :description => "Additional disks you'd like to have attached to this instance (NOTE: this will not create them)"

      option :gce_auto_restart,
        :long => "--[no-]gce-auto-server-restart",
        :description => "Compute Engine can automatically restart your VM instance if it is terminated for non-user-initiated reasons; enabled by default.",
        :boolean => true,
        :default => true

      option :gce_auto_migrate,
        :long => "--[no-]gce-auto-server-migrate",
        :description => "Compute Engine can migrate your VM instance to other hardware without downtime prior to periodic infrastructure maintenance, otherwise the server is terminated; enabled by default.",
        :boolean => true,
        :default => true

      option :gce_can_ip_forward,
        :long => "--[no-]gce-can-ip-forward",
        :description => "Forwarding allows the instance to help route packets.",
        :boolean => true,
        :default => false

      option :gce_network,
        :short => "-n NETWORK",
        :long => "--gce-network NETWORK",
        :description => "The network for this server; default is 'default'",
        :default => "default"

      option :gce_tags,
        :short => "-T TAG1,TAG2,TAG3",
        :long => "--gce-tags TAG1,TAG2,TAG3",
        :description => "Tags for this server",
        :proc => Proc.new { |tags| tags.split(',') },
        :default => []

      option :gce_metadata,
        :long => "--gce-metadata Key=Value[,Key=Value...]",
        :description => "Additional metadata for this server",
        :proc => Proc.new { |metadata| metadata.split(',') },
        :default => []

      option :gce_metadata_from_file,
        :long => "--gce-metadata-from-file Key=File[,Key=File...]",
        :description => "Additional metadata loaded from a YAML file",
        :proc => Proc.new { |metadata| metadata.split(',') },
        :default => []

      option :gce_service_account_scopes,
        :long => "--gce-service-account-scopes SCOPE1,SCOPE2,SCOPE3",
        :proc => Proc.new { |service_account_scopes| service_account_scopes.split(',') },
        :description => "Service account scopes for this server",
        :default => []

      # GCE documentation uses the term 'service account name', the api uses the term 'email'
      option :gce_service_account_name,
        :long => "--gce-service-account-name NAME",
        :description => "Service account name for this server, typically in the form of '123845678986@project.gserviceaccount.com'; default is 'default'",
        :default => "default"

      option :gce_server_connect_ip,
        :long => "--gce-server-connect-ip INTERFACE",
        :description => "Whether to use PUBLIC or PRIVATE interface/address to connect; default is 'PUBLIC'",
        :default => 'PUBLIC'

      option :gce_public_ip,
        :long=> "--gce-public-ip IP_ADDRESS",
        :description => "EPHEMERAL or static IP address or NONE; default is 'EPHEMERAL'",
        :default => "EPHEMERAL"

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The Chef node name for your new node"

      option :ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The ssh username; default is 'root'",
        :default => "root"

      option :ssh_password,
        :short => "-P PASSWORD",
        :long => "--ssh-password PASSWORD",
        :description => "The ssh password"

      option :ssh_port,
        :short => "-p PORT",
        :long => "--ssh-port PORT",
        :description => "The ssh port; default is '22'",
        :default => "22"

      option :ssh_gateway,
        :short => "-w GATEWAY",
        :long => "--ssh-gateway GATEWAY",
        :description => "The ssh gateway server"

      option :identity_file,
        :short => "-i IDENTITY_FILE",
        :long => "--identity-file IDENTITY_FILE",
        :description => "The SSH identity file used for authentication"

      option :prerelease,
        :long => "--prerelease",
        :description => "Install the pre-release chef gems"

      option :bootstrap_version,
        :long => "--bootstrap-version VERSION",
        :description => "The version of Chef to install",
        :proc => Proc.new { |v| Chef::Config[:knife][:bootstrap_version] = v }

      option :distro,
        :short => "-d DISTRO",
        :long => "--distro DISTRO",
        :description => "Bootstrap a distro using a template; default is 'chef-full'",
        :default => 'chef-full'

      option :template_file,
        :long => "--template-file TEMPLATE",
        :description => "Full path to location of template to use",
        :default => false

      option :run_list,
        :short => "-r RUN_LIST",
        :long => "--run-list RUN_LIST",
        :description => "Comma separated list of roles/recipes to apply",
        :proc => lambda { |o| o.split(/[\s,]+/) }

      option :json_attributes,
        :short => "-j JSON",
        :long => "--json-attributes JSON",
        :description => "A JSON string to be added to the first run of chef-client",
        :proc => lambda { |o| JSON.parse(o) }

      option :host_key_verify,
        :long => "--[no-]host-key-verify",
        :description => "Verify host key, enabled by default.",
        :boolean => true,
        :default => true

      option :compute_user_data,
        :long => "--user-data USER_DATA_FILE",
        :short => "-u USER_DATA_FILE",
        :description => "The Google Compute User Data file to provision the server with"

      option :hint,
        :long => "--hint HINT_NAME[=HINT_FILE]",
        :description => "Specify Ohai Hint to be set on the bootstrap target. Use multiple --hint options to specify multiple hints.",
        :proc => Proc.new { |h|
           Chef::Config[:knife][:hints] ||= {}
           name, path = h.split("=")
           Chef::Config[:knife][:hints][name] = path ? JSON.parse(::File.read(path)) : Hash.new
        }

      option :secret,
        :short => "-s SECRET",
        :long => "--secret ",
        :description => "The secret key to use to encrypt data bag item values",
        :proc => lambda { |s| Chef::Config[:knife][:secret] = s }

      option :secret_file,
        :long => "--secret-file SECRET_FILE",
        :description => "A file containing the secret key to use to encrypt data bag item values",
        :proc => lambda { |sf| Chef::Config[:knife][:secret_file] = sf }

      def tcp_test_ssh(hostname, ssh_port)
        tcp_socket = TCPSocket.new(hostname, ssh_port)
        readable = IO.select([tcp_socket], nil, nil, 5)
        if readable
          Chef::Log.debug("sshd accepting connections on #{hostname}, banner is #{tcp_socket.gets}")
          yield
          true
        else
          false
        end
      rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH, IOError
        sleep 2
        false
      rescue Errno::EPERM, Errno::ETIMEDOUT
        false
      ensure
        tcp_socket && tcp_socket.close
      end

      def wait_for_sshd(hostname)
        config[:ssh_gateway] ? wait_for_tunnelled_sshd(hostname) : wait_for_direct_sshd(hostname, config[:ssh_port])
      end

      def wait_for_tunnelled_sshd(hostname)
        print(".")
        print(".") until tunnel_test_ssh(hostname) {
          sleep @initial_sleep_delay ||= 40
          puts("done")
        }
      end

      def tunnel_test_ssh(hostname, &block)
        gw_host, gw_user = config[:ssh_gateway].split('@').reverse
        gw_host, gw_port = gw_host.split(':')
        gateway = Net::SSH::Gateway.new(gw_host, gw_user, :port => gw_port || 22)
        status = false
        gateway.open(hostname, config[:ssh_port]) do |local_tunnel_port|
          status = tcp_test_ssh('localhost', local_tunnel_port, &block)
        end
        status
      rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH, IOError
        sleep 2
        false
      rescue Errno::EPERM, Errno::ETIMEDOUT
        false
      end

      def wait_for_direct_sshd(hostname, ssh_port)
        print(".") until tcp_test_ssh(ssh_connect_host, ssh_port) {
          sleep @initial_sleep_delay ||=  40
          puts("done")
        }
      end

      def ssh_connect_host
        @ssh_connect_host ||= if locate_config_value(:gce_server_connect_ip) == 'PUBLIC'
                                public_ips(@instance).first
        else
           private_ips(@instance).first
        end
      end

      def disk_exists(disk, zone)
        # if client.disks.get errors with a Google::Compute::ResourceNotFound
        # then the disk does not exist and can be created
        client.disks.get(:disk => disk, :zone => selflink2name(zone))
      rescue Google::Compute::ResourceNotFound
        # disk does not exist
        # continue provisioning
        false
      else
        true
      end

      def wait_for_disk(disk, operation, zone)
        Timeout::timeout(300) do
          until disk.status == 'DONE'
            ui.info(".")
            sleep 1
            disk = client.zoneOperations.get(:name => disk,
                                             :operation => operation,
                                             :zone => selflink2name(zone))
          end
          disk.target_link
        end
      rescue Timeout::Error
        ui.error("Timeout exceeded with disk status: " + disk.status)
        exit 1
      end

      def bootstrap_for_node(instance, ssh_host)
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args = [ssh_host]
        bootstrap.config[:run_list] = locate_config_value(:run_list)
        bootstrap.config[:ssh_user] = locate_config_value(:ssh_user)
        bootstrap.config[:ssh_port] = locate_config_value(:ssh_port)
        bootstrap.config[:ssh_gateway] = locate_config_value(:ssh_gateway)
        bootstrap.config[:identity_file] = locate_config_value(:identity_file)
        bootstrap.config[:chef_node_name] = locate_config_value(:chef_node_name) || instance.name
        bootstrap.config[:prerelease] = locate_config_value(:prerelease)
        bootstrap.config[:bootstrap_version] = locate_config_value(:bootstrap_version)
        bootstrap.config[:first_boot_attributes] = locate_config_value(:json_attributes)
        bootstrap.config[:distro] = locate_config_value(:distro)
        bootstrap.config[:use_sudo] = true unless locate_config_value(:ssh_user) == 'root'
        bootstrap.config[:template_file] = locate_config_value(:template_file)
        bootstrap.config[:environment] = locate_config_value(:environment)
        bootstrap.config[:encrypted_data_bag_secret] = locate_config_value(:encrypted_data_bag_secret)
        bootstrap.config[:encrypted_data_bag_secret_file] = locate_config_value(:encrypted_data_bag_secret_file)
        bootstrap.config[:secret] = locate_config_value(:secret)
        bootstrap.config[:secret_file] = locate_config_value(:secret_file)

        # may be needed for vpc_mode
        bootstrap.config[:host_key_verify] = locate_config_value(:host_key_verify)
        # Modify global configuration state to ensure hint gets set by
        # knife-bootstrap
        Chef::Config[:knife][:hints] ||= {}
        Chef::Config[:knife][:hints]["gce"] ||= {}
        Chef::Config[:knife][:hints]["google"] ||= {}
        bootstrap
      end

      def run
        $stdout.sync = true
        unless @name_args.size > 0
          ui.error("Please provide the name of the new server.")
          exit 1
        end

        begin
          zone = client.zones.get(locate_config_value(:gce_zone)).self_link
        rescue Google::Compute::ResourceNotFound
          ui.error("Zone '#{locate_config_value(:gce_zone)}' not found.")
          exit 1
        rescue Google::Compute::ParameterValidation
          ui.error("Must specify zone in knife config file or in command line as an option. Try --help.")
          exit 1
        end

        begin
          machine_type = client.machine_types.get(:name => locate_config_value(:gce_machine_type),
                                                  :zone => selflink2name(zone)).self_link
        rescue Google::Compute::ResourceNotFound
          ui.error("MachineType '#{locate_config_value(:gce_machine_type)}' not found")
          exit 1
        end

        # this parameter is a string during the post and boolean otherwise
        if locate_config_value(:gce_auto_restart) then
          auto_restart = 'true'
        else
          auto_restart = 'false'
        end

        if locate_config_value(:gce_auto_migrate) then
          auto_migrate = 'MIGRATE'
        else
          auto_migrate = 'TERMINATE'
        end

        if locate_config_value(:gce_can_ip_forward) then
          can_ip_forward = true
        else
          can_ip_forward = false
        end

        (checked_custom, checked_all) = false
        begin
          image_project = locate_config_value(:gce_image_project_id)
          # use zone url to determine project name
          zone =~ Regexp.new('/projects/(.*?)/')
          project = $1
          if image_project.to_s.empty?
            unless checked_custom
              checked_custom = true
              ui.info("Looking for Image '#{locate_config_value(:gce_image)}' in Project '#{project}'")
              image = client.images.get(:project=>project, :name=>locate_config_value(:gce_image)).self_link
            else
              case config[:gce_image].downcase
              when /centos/
                project = 'centos-cloud'
             when /container-vm/
                project = 'google-containers'
             when /coreos/
                project = 'coreos-cloud'
              when /debian/
                project = 'debian-cloud'
             when /opensuse-cloud/
                project = 'opensuse-cloud'
              when /rhel/
                project = 'rhel-cloud'
              when /sles/
                project = 'suse-cloud'
              when /ubuntu/
                project = 'ubuntu-os-cloud'
              end
              checked_all = true
              ui.info("Looking for Image '#{locate_config_value(:gce_image)}' in Project '#{project}'")
              image = client.images.get(:project=>project, :name=>locate_config_value(:gce_image)).self_link
            end
          else
            checked_all = true
            project = image_project
            image = client.images.get(:project=>project, :name=>locate_config_value(:gce_image)).self_link
          end
          ui.info("Found Image '#{locate_config_value(:gce_image)}' in Project '#{project}'")
        rescue Google::Compute::ResourceNotFound
          unless checked_all then
            retry
          else
            ui.error("Image '#{locate_config_value(:gce_image)}' not found")
            exit 1
          end
        end

        begin
          boot_disk_size = locate_config_value(:gce_boot_disk_size).to_i
          raise if !boot_disk_size.between?(10, 10000)
        rescue
          ui.error("Size of the persistent boot disk must be between 10 and 10000 GB.")
          exit 1
        end

        if locate_config_value(:gce_boot_disk_ssd) then
          boot_disk_type = "#{zone}/diskTypes/pd-ssd"
        else
          boot_disk_type = "#{zone}/diskTypes/pd-standard"
        end

        if locate_config_value(:gce_boot_disk_name).to_s.empty? then
          boot_disk_name = @name_args.first
        else
          boot_disk_name = locate_config_value(:gce_boot_disk_name)
        end

        if locate_config_value(:gce_boot_disk_autodelete) then
          boot_disk_autodelete = 'true'
        else
          boot_disk_autodelete = 'false'
        end

        ui.info("Waiting for the boot disk insert operation to complete")
        msg_pair("Name", boot_disk_name)
        msg_pair("Zone", selflink2name(zone))
        msg_pair("Type", selflink2name(boot_disk_type))
        msg_pair("Size", "#{boot_disk_size} gb")
        msg_pair("Image", selflink2name(image))
        boot_disk_insert = client.disks.insert(:sourceImage => image,
                                               :zone => selflink2name(zone),
                                               :name => boot_disk_name,
                                               :type => boot_disk_type,
                                               :sizeGb => boot_disk_size)
        boot_disk_target_link = wait_for_disk(boot_disk_insert, boot_disk_insert.name, zone)
        disks = [{'boot' => true,
                  'diskType' => boot_disk_type,
                  'type' => 'PERSISTENT',
                  'mode' => 'READ_WRITE',
                  'deviceName' => selflink2name(boot_disk_target_link),
                  'source' => boot_disk_target_link,
                  'autoDelete' => boot_disk_autodelete
                  }]

        unless locate_config_value(:gce_additional_disks).to_s.empty? then
          ui.info("Waiting for the spare disk insert operation to complete")

          additional_disks_parameter = locate_config_value(:gce_additional_disks).to_s.split(',').map do |additional_disk|
            client.disks.list(:zone => selflink2name(zone),
                                 :name => additional_disk).
            select do |link|
              # Occatioally AppEngine will give up and return all disks
              # when this happens find the correct one
              link.self_link =~ /#{additional_disk}/
            end.first
          end.map do |disk|
            if disk.nil?
              ui.error("None of the disks in '#{locate_config_value(:gce_additional_disks)}' were found")
              exit 1
            end
            {'boot' => false,
             'type' => 'PERSISTENT',
             'mode' => 'READ_WRITE',
             'deviceName' => selflink2name(disk.self_link),
             'source' => disk.self_link}
          end

          disks.push(*additional_disks_parameter)
        end

        begin
          network = client.networks.get(locate_config_value(:gce_network)).self_link
        rescue Google::Compute::ResourceNotFound
          ui.error("Network '#{locate_config_value(:gce-network)}' not found")
          exit 1
        end

        metadata_items = []

        locate_config_value(:gce_metadata).collect do |pair|
          mkey, mvalue = pair.split('=')
          metadata_items << {'key' => mkey, 'value' => mvalue}
        end

        # Metadata from file

        locate_config_value(:gce_metadata_from_file).each do |p|
          mkey, filename = p.split('=')
          begin
            file_content = File.read(filename)
          rescue
            puts "Not possible to read metadata file #{filename}"
          end
          metadata_items << {'key' => mkey, 'value' => file_content}
        end

        network_interface = {'network'=>network}

        public_ip = locate_config_value(:gce_public_ip)
        if public_ip == 'EPHEMERAL'
          network_interface.merge!('accessConfigs' =>[{"name"=>"External NAT",
                                  "type"=> "ONE_TO_ONE_NAT"}])
        elsif public_ip =~ /\d+\.\d+\.\d+\.\d+/
          network_interface.merge!('accessConfigs' =>[{"name"=>"External NAT",
                  "type"=>"ONE_TO_ONE_NAT", "natIP"=>public_ip}])
        elsif public_ip == 'NONE'
          config[:gce_server_connect_ip] = 'PRIVATE'
        else
          ui.error("Invalid public ip value : #{public_ip}")
          exit 1
        end

        ui.info("Waiting for the create server operation to complete")
        if !locate_config_value(:gce_service_account_scopes).any?
          zone_operation = client.instances.create(:name => @name_args.first,
                                                   :zone => selflink2name(zone),
                                                   :machineType => machine_type,
                                                   :disks => disks,
                                                   :canIpForward => can_ip_forward,
                                                   :networkInterfaces => [network_interface],
                                                   :scheduling => {
                                                     'automaticRestart' => auto_restart,
                                                     'onHostMaintenance' => auto_migrate
                                                   },
                                                   :metadata => { 'items' => metadata_items },
                                                   :tags => { 'items' => locate_config_value(:gce_tags) }
                                                  )
        else
          zone_operation = client.instances.create(:name => @name_args.first,
                                                   :zone=> selflink2name(zone),
                                                   :machineType => machine_type,
                                                   :disks => disks,
                                                   :canIpForward => can_ip_forward,
                                                   :networkInterfaces => [network_interface],
                                                   :serviceAccounts => [{
                                                     'kind' => 'compute#serviceAccount',
                                                     'email' => locate_config_value(:gce_service_account_name),
                                                     'scopes' => locate_config_value(:gce_service_account_scopes)
                                                   }],
                                                   :scheduling => {
                                                     'automaticRestart' => auto_restart,
                                                     'onHostMaintenance' => auto_migrate
                                                   },
                                                   :metadata => { 'items'=>metadata_items },
                                                   :tags => { 'items' => locate_config_value(:gce_tags) }
                                                  )
        end

        until zone_operation.progress.to_i == 100
          ui.info(".")
          sleep 1
          zone_operation = client.zoneOperations.get(:name=>zone_operation, :operation=>zone_operation.name, :zone=>selflink2name(zone))
        end

        ui.info("Waiting for the servers to be in running state")

        @instance = client.instances.get(:name=>@name_args.first, :zone=>selflink2name(zone))
        msg_pair("Instance Name", @instance.name)
        msg_pair("Machine Type", selflink2name(@instance.machine_type))
        msg_pair("Image", selflink2name(config[:gce_image]))
        msg_pair("Zone", selflink2name(@instance.zone))
        msg_pair("Tags", @instance.tags.has_key?("items") ? @instance.tags["items"].join(",") : "None")
        until @instance.status == "RUNNING"
          sleep 3
          msg_pair("Status", @instance.status.downcase)
          @instance = client.instances.get(:name=>@name_args.first, :zone=>selflink2name(zone))
        end

        msg_pair("Public IP Address", public_ips(@instance)) unless public_ips(@instance).empty?
        msg_pair("Private IP Address", private_ips(@instance))
        ui.info("\n#{ui.color("Waiting for server", :magenta)}")

        ui.info("\n")
        ui.info(ui.color("Waiting for sshd", :magenta))
        wait_for_sshd(ssh_connect_host)
        bootstrap_for_node(@instance,ssh_connect_host).run
        ui.info("\n")
        ui.info("Complete!!")
      end
    end
  end
end
