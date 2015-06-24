#
# Author:: Paul Rossman (<paulrossman@google.com>)
# Copyright:: Copyright 2015 Google Inc. All Rights Reserved.
# License:: Apache License, Version 2.0
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

require 'chef/knife/google_base'

class Chef
  class Knife
    class GoogleServerCreate < Knife

      include Knife::GoogleBase

      deps do
        require 'chef/knife/bootstrap'
        require 'timeout'
        Chef::Knife::Bootstrap.load_deps
      end

      banner "knife google server create NAME -m MACHINE_TYPE -I IMAGE (options)"

      attr_accessor :initial_sleep_delay
      attr_reader :instance

      option :machine_type,
        :short => "-m MACHINE_TYPE",
        :long => "--gce-machine-type MACHINE_TYPE",
        :description => "The machine type of server (n1-highcpu-2, n1-highcpu-2-d, etc)",
        :required => true

      option :image,
        :short => "-I IMAGE",
        :long => "--gce-image IMAGE",
        :description => "The Image for the server",
        :required => true

      option :image_project_id,
        :long => "--gce-image-project-id IMAGE_PROJECT_ID",
        :description => "The project-id containing the Image (debian-cloud, centos-cloud, etc)",
        :default => ""

      option :gce_zone,
        :short => "-Z ZONE",
        :long => "--gce-zone ZONE",
        :description => "The Zone for this server"

      option :boot_disk_name,
        :long => "--gce-boot-disk-name DISK",
        :description => "Name of persistent boot disk; default is to use the server name",
        :default => ""

      option :boot_disk_size,
        :long => "--gce-boot-disk-size SIZE",
        :description => "Size of the persistent boot disk between 10 and 10000 GB, specified in GB; default is '10' GB",
        :default => "10"

      option :boot_disk_ssd,
        :long => "--[no-]gce-boot-disk-ssd",
        :description => "Use pd-ssd boot disk; default is pd-standard boot disk",
        :boolean => true,
        :default => false

      option :boot_disk_autodelete,
        :long => "--[no-]gce-boot-disk-autodelete",
        :description => "Delete boot disk when server is deleted.",
        :boolean => true,
        :default => false

      option :additional_disks,
        :long => "--gce-disk-additional-disks DISKS",
        :short => "-D DISKS",
        :description => "Additional disks to attach to this server (NOTE: this will not create them)"

      option :auto_restart,
        :long => "--[no-]gce-auto-server-restart",
        :description => "GCE can automatically restart your server if it is terminated for non-user-initiated reasons; enabled by default.",
        :boolean => true,
        :default => true

      option :auto_migrate,
        :long => "--[no-]gce-auto-server-migrate",
        :description => "GCE can migrate your server to other hardware without downtime prior to periodic infrastructure maintenance, otherwise the server is terminated; enabled by default.",
        :boolean => true,
        :default => true

      option :can_ip_forward,
        :long => "--[no-]gce-can-ip-forward",
        :description => "Allow server network forwarding",
        :boolean => true,
        :default => false

      option :network,
        :short => "-n NETWORK",
        :long => "--gce-network NETWORK",
        :description => "The network for this server; default is 'default'",
        :default => "default"

      option :tags,
        :short => "-T TAG1,TAG2,TAG3",
        :long => "--gce-tags TAG1,TAG2,TAG3",
        :description => "Tags for this server",
        :proc => Proc.new { |tags| tags.split(',') },
        :default => []

      option :metadata,
        :long => "--gce-metadata Key=Value[,Key=Value...]",
        :description => "Additional metadata for this server",
        :proc => Proc.new { |metadata| metadata.split(',') },
        :default => []

      option :metadata_from_file,
        :long => "--gce-metadata-from-file Key=File[,Key=File...]",
        :description => "Additional metadata loaded from a YAML file",
        :proc => Proc.new { |metadata| metadata.split(',') },
        :default => []

      option :service_account_scopes,
        :long => "--gce-service-account-scopes SCOPE1,SCOPE2,SCOPE3",
        :proc => Proc.new { |service_account_scopes| service_account_scopes.split(',') },
        :description => "Service account scopes for this server",
        :default => []

      # GCE documentation uses the term 'service account name', the api uses the term 'email'
      option :service_account_name,
        :long => "--gce-service-account-name NAME",
        :description => "Service account name for this server, typically in the form of '123845678986@project.gserviceaccount.com'; default is 'default'",
        :default => "default"

      option :server_connect_interface,
        :long => "--gce-server-connect-interface INTERFACE",
        :description => "Whether to use PUBLIC or PRIVATE interface to connect; default is 'PUBLIC'",
        :default => 'PUBLIC'

      option :public_ip,
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
        :description => "The version of Chef to install"

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
        :proc => lambda { |o| MultiJson.load(o) }

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
           Chef::Config[:knife][:hints][name] = path ? MultiJson.load(::File.read(path)) : Hash.new
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
        ui.info("Waiting for direct ssh to #{hostname}:#{ssh_port}") until tcp_test_ssh(hostname, ssh_port) {
          sleep @initial_sleep_delay ||=  10
          ui.info(ui.color("Connected to server", :magenta))
        }
      end

      def wait_for_tunneled_sshd(hostname)
        ui.info("Waiting for tunneled ssh to #{hostname}") until tunnel_test_ssh(hostname) {
          sleep @initial_sleep_delay ||= 10
          ui.info(ui.color("Connected to server", :magenta))
        }
      end

      def wait_for_sshd(hostname)
        config[:ssh_gateway] ? wait_for_tunneled_sshd(hostname) : wait_for_direct_sshd(hostname, config[:ssh_port])
      end

      def bootstrap_for_node(instance_name, ssh_host)
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args = [ssh_host]
        bootstrap.config[:run_list] = config[:run_list]
        bootstrap.config[:ssh_user] = config[:ssh_user]
        bootstrap.config[:ssh_port] = config[:ssh_port]
        bootstrap.config[:ssh_gateway] = config[:ssh_gateway]
        bootstrap.config[:identity_file] = config[:identity_file]
        bootstrap.config[:chef_node_name] = config[:chef_node_name] || instance_name
        bootstrap.config[:prerelease] = config[:prerelease]
        bootstrap.config[:bootstrap_version] = config[:bootstrap_version]
        bootstrap.config[:first_boot_attributes] = config[:json_attributes]
        bootstrap.config[:distro] = config[:distro]
        bootstrap.config[:use_sudo] = true unless config[:ssh_user] == 'root'
        bootstrap.config[:template_file] = config[:template_file]
        bootstrap.config[:environment] = config[:environment]
        bootstrap.config[:encrypted_data_bag_secret] = locate_config_value(:encrypted_data_bag_secret)
        bootstrap.config[:encrypted_data_bag_secret_file] = locate_config_value(:encrypted_data_bag_secret_file)
        bootstrap.config[:secret] = locate_config_value(:secret)
        bootstrap.config[:secret_file] = locate_config_value(:secret_file)
        # may be needed for vpc_mode
        bootstrap.config[:host_key_verify] = config[:host_key_verify]
        # Modify global configuration state to ensure hint gets set by knife-bootstrap
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

        if config[:auto_migrate] then
          auto_migrate = 'MIGRATE'
        else
          auto_migrate = 'TERMINATE'
        end

        # this parameter is a string during the post and boolean otherwise
        if config[:auto_restart] then
          auto_restart = 'true'
        else
          auto_restart = 'false'
        end

        if config[:boot_disk_autodelete] then
          boot_disk_autodelete = 'true'
        else
          boot_disk_autodelete = 'false'
        end

        if config[:boot_disk_name].to_s.empty? then
          boot_disk_name = @name_args.first
        else
          boot_disk_name = config[:boot_disk_name]
        end

        begin
          boot_disk_size = config[:boot_disk_size].to_i
          raise if !boot_disk_size.between?(10, 10000)
        rescue
          ui.error("Size of the boot disk must be between 10 and 10000 GB.")
          raise
        end

        if config[:boot_disk_ssd] then
          boot_disk_type = "zones/#{config[:gce_zone]}/diskTypes/pd-ssd"
        else
          boot_disk_type = "zones/#{config[:gce_zone]}/diskTypes/pd-standard"
        end

        if config[:can_ip_forward] then
          can_ip_forward = true
        else
          can_ip_forward = false
        end

        begin
          result = client.execute(
            :api_method => compute.machine_types.get,
            :parameters => {:project => config[:gce_project], :zone => config[:gce_zone], :machineType => config[:machine_type]})
          body = MultiJson.load(result.body, :symbolize_keys => true)
          machine_type = body[:selfLink]
          raise(body[:error][:message]) if result.status != 200
        rescue => e
          ui.error(e)
          raise
        end

        begin
          ui.info(ui.color("Looking for image", :magenta))
          project = config[:image_project_id]
          if project.to_s.empty?
            # no project specified so assume use of public image
            case config[:image].downcase
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
          end
          result = client.execute(
            :api_method => compute.images.list,
            :parameters => {:project => project, :filter => "name eq ^#{config[:image]}$"})
          body = MultiJson.load(result.body, :symbolize_keys => true)
          if body[:items][0][:name] == config[:image]
            source_image = body[:items][0][:selfLink]
            ui.info("found image '#{selflink2name(source_image)}' in project '#{project}'")
          else
            raise "#{selflink2name(source_image)} not found"
          end
        rescue => e
          ui.error(e)
          raise
        end

        begin
          ui.info(ui.color("Creating boot disk", :magenta))
          result = client.execute(
            :api_method => compute.disks.insert,
            :parameters => {:project => config[:gce_project], :zone => config[:gce_zone], :sourceImage => source_image},
            :body_object => {:name => boot_disk_name, :sizeGb => boot_disk_size.to_i, :type => boot_disk_type})
          body = MultiJson.load(result.body, :symbolize_keys => true)
          # this will not catch all possible errors
          raise "#{body[:error][:message]}" if result.status != 200
        rescue => e
          ui.error(e)
          raise
        end

        disks = []
        begin
          Timeout::timeout(120) do
            status = ""
            until status == "READY"
              sleep 2
              result = client.execute(
                :api_method => compute.disks.get,
                :parameters => {:project => config[:gce_project], :zone => config[:gce_zone], :disk => boot_disk_name})
              body = MultiJson.load(result.body, :symbolize_keys => true)
              ui.info("disk #{body[:status].downcase}") unless body[:status].empty?
              status = body[:status]
            end
            disks = [{'autoDelete' => boot_disk_autodelete,
                      'boot' => true,
                      'deviceName' => boot_disk_name,
                      'mode' => "READ_WRITE",
                      'source' => body[:selfLink],
                      'type' => "PERSISTENT"}]
          end
        rescue Timeout::Error
          ui.error("Timeout exceeded with disk status: #{status}")
          raise
        rescue => e
          ui.error(e)
          raise
        end

        begin
          unless config[:additional_disks].to_s.empty? then
            ui.info(ui.color("Attaching additional disk(s)", :magenta))
            config[:additional_disks].to_s.split(',').map do |additional_disk|
              result = client.execute(
                :api_method => compute.disks.get,
                :parameters => {:project => config[:gce_project], :zone => config[:gce_zone], :disk => additional_disk})
              body = MultiJson.load(result.body, :symbolize_keys => true)
              # TODO add some status notification
              # TODO add some sort of validation or error checking
              disks.push({'boot' => false,
                          'deviceName' => body[:name],
                          'mode' => "READ_WRITE",
                          'source' => body[:selfLink],
                          'type' => "PERSISTENT"})
            end
          end
        rescue => e
          ui.error(e)
          raise
        end

        # metadata

        metadata_items = []
        config[:metadata].collect do |pair|
          mkey, mvalue = pair.split('=')
          metadata_items << {'key' => mkey, 'value' => mvalue}
        end

        # metadata from file

        config[:metadata_from_file].each do |p|
          mkey, filename = p.split('=')
          begin
            file_content = File.read(filename)
          rescue
            ui.error("Could not read metadata file #{filename}")
          end
          metadata_items << {'key' => mkey, 'value' => file_content}
        end

        # network

        begin
          result = client.execute(
            :api_method => compute.networks.get,
            :parameters => {:project => config[:gce_project], :network => config[:network]})
          body = MultiJson.load(result.body, :symbolize_keys => true)
          network = body[:selfLink]
        rescue => e
          ui.error("Network '#{config[:network]}' not found")
          raise
        end

        network_interface = {"network" => network}

        if config[:public_ip] == "EPHEMERAL"
          network_interface.merge!("accessConfigs" => [{"name" => "External NAT", "type" => "ONE_TO_ONE_NAT"}])
        elsif config[:public_ip] =~ /\d+\.\d+\.\d+\.\d+/
          network_interface.merge!("accessConfigs" => [{"name" => "External NAT", "type" => "ONE_TO_ONE_NAT", "natIP" => config[:public_ip]}])
        elsif config[:public_ip] == "NONE"
          config[:server_connect_interface] = "PRIVATE"
        else
          ui.error("Invalid public ip value : #{config[:public_ip]}")
          raise
        end

        ui.info(ui.color("Creating server", :magenta))
        if !config[:service_account_scopes].any?
          begin
            result = client.execute(
              :api_method => compute.instances.insert,
              :parameters => {:project => config[:gce_project], :zone => config[:gce_zone]},
              :body_object => {:name => @name_args.first,
                               :machineType => machine_type,
                               :disks => disks,
                               :canIpForward => can_ip_forward,
                               :networkInterfaces => [network_interface],
                               :scheduling => {'automaticRestart' => auto_restart,
                                               'onHostMaintenance' => auto_migrate},
                               :metadata => {'items' => metadata_items},
                               :tags => {'items' => config[:tags]}})
            body = MultiJson.load(result.body, :symbolize_keys => true)
            # this will not catch all possible errors
            raise "#{body[:error][:message]}" if result.status != 200
          rescue => e
            ui.error(e)
            raise
          end
        else
          begin
            result = client.execute(
              :api_method => compute.instances.insert,
              :parameters => {:project => config[:gce_project], :zone => config[:gce_zone]},
              :body_object => {:name => @name_args.first,
                               :machineType => machine_type,
                               :disks => disks,
                               :canIpForward => can_ip_forward,
                               :networkInterfaces => [network_interface],
                               :serviceAccounts => [{'kind' => 'compute#serviceAccount',
                                                     'email' => config[:service_account_name],
                                                     'scopes' => config[:service_account_scopes]}],
                               :scheduling => {'automaticRestart' => auto_restart,
                                               'onHostMaintenance' => auto_migrate},
                               :metadata => {'items' => metadata_items},
                               :tags => {'items' => config[:tags]}})
            body = MultiJson.load(result.body, :symbolize_keys => true)
            # this will not catch all possible errors
            raise "#{body[:error][:message]}" if result.status != 200
          rescue => e
            ui.error(e)
            raise
          end
        end

        begin
          sleep 2
          Timeout::timeout(120) do
            status = ""
            until status == "RUNNING"
              sleep 2
              result = client.execute(
                :api_method => compute.instances.get,
                :parameters => {:project => config[:gce_project], :zone => config[:gce_zone], :instance => @name_args.first})
              body = MultiJson.load(result.body, :symbolize_keys => true)
              ui.info("server #{body[:status].downcase}") unless body[:status].empty?
              status = body[:status]
              # TODO raise if status == STOPPING or TERMINATED
            end
          end
          private_ip = body[:networkInterfaces].find { |n| n[:name] == "nic0" }[:networkIP]
          if body[:networkInterfaces].find { |n| n[:name] == "nic0" }[:accessConfigs]
            public_ip = body[:networkInterfaces].find { |n| n[:name] == "nic0" }[:accessConfigs][0][:natIP]
          else
            public_ip = "NONE"
          end
          ui.info("\n")
          msg_pair("Instance Name", @name_args.first)
          msg_pair("Machine Type", selflink2name(machine_type))
          msg_pair("Image", selflink2name(source_image))
          msg_pair("Zone", config[:gce_zone])
          msg_pair("Public IP Address", public_ip)
          msg_pair("Private IP Address", private_ip)
          ui.info("\n")
          ui.info(ui.color("Waiting for sshd", :magenta))
          ssh_connect_ip = if config[:server_connect_interface] == "PUBLIC"
                             public_ip
                           else
                             private_ip
                           end
          wait_for_sshd(ssh_connect_ip)
          bootstrap_for_node(@name_args.first, ssh_connect_ip).run
        rescue Timeout::Error
          ui.error("Timeout exceeded with status: #{status}")
          raise
        rescue => e
          ui.error(e)
          raise
        end

        ui.info("\n")
        ui.info("Complete!!")
      end
    end
  end
end
