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

      option :machine_type,
        :short => "-m MACHINE_TYPE",
        :long => "--google-compute-machine MACHINE_TYPE",
        :description => "The machine type of server (n1-highcpu-2, n1-highcpu-2-d, etc)",
        :required => true

      option :image,
        :short => "-I IMAGE",
        :long => "--google-compute-image IMAGE",
        :description => "The Image for the server",
        :required => true

      option :image_project_id,
        :short => "-J IMAGE_PROJECT_ID",
        :long => "--google-compute-image-project-id IMAGE_PROJECT_ID",
        :description => "The project-id containing the Image (debian-cloud, centos-cloud, etc)",
        :default => "" 

      option :zone,
        :short => "-Z ZONE",
        :long => "--google-compute-zone ZONE",
        :description => "The Zone for this server"

      option :network,
        :short => "-n NETWORK",
        :long => "--google-compute-network NETWORK",
        :description => "The network for this server; default is 'default'",
        :default => "default"

      option :tags,
        :short => "-T TAG1,TAG2,TAG3",
        :long => "--google-compute-tags TAG1,TAG2,TAG3",
        :description => "Tags for this server",
        :proc => Proc.new { |tags| tags.split(',') },
        :default => []

      option :metadata,
        :short => "-M K=V[,K=V,...]",
        :long => "--google-compute-metadata Key=Value[,Key=Value...]",
        :description => "The metadata for this server",
        :proc => Proc.new { |metadata| metadata.split(',') },
        :default => []

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

      option :instance_connect_ip,
        :long => "--google-compute-server-connect-ip PUBLIC",
        :short => "-a PUBLIC",
        :description => "Whether to use PUBLIC or PRIVATE address to connect; default is 'PUBLIC'",
        :default => 'PUBLIC'

      option :disks,
        :long=> "--google-compute-disks DISK1,DISK2",
        :proc => Proc.new { |metadata| metadata.split(',') },
        :description => "Disks to be attached",
        :default => []

      option :public_ip,
        :long=> "--google-compute-public-ip IP_ADDRESS",
        :description => "EPHEMERAL or static IP address or NONE; default is 'EPHEMERAL'",
        :default => "EPHEMERAL"

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
        print(".") until tunnel_test_ssh(ssh_connect_host) {
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
        @ssh_connect_host ||= if config[:instance_connect_ip] == 'PUBLIC'
                                public_ips(@instance).first
        else
           private_ips(@instance).first
        end
      end

      def bootstrap_for_node(instance,ssh_host)
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args = [ssh_host]
        bootstrap.config[:run_list] = config[:run_list]
        bootstrap.config[:ssh_user] = config[:ssh_user]
        bootstrap.config[:ssh_port] = config[:ssh_port]
        bootstrap.config[:ssh_gateway] = config[:ssh_gateway]
        bootstrap.config[:identity_file] = config[:identity_file]
        bootstrap.config[:chef_node_name] = config[:chef_node_name] || instance.name
        bootstrap.config[:prerelease] = config[:prerelease]
        bootstrap.config[:bootstrap_version] = config[:bootstrap_version]
        bootstrap.config[:first_boot_attributes] = config[:json_attributes]
        bootstrap.config[:distro] = config[:distro]
        bootstrap.config[:use_sudo] = true unless config[:ssh_user] == 'root'
        bootstrap.config[:template_file] = config[:template_file]
        bootstrap.config[:environment] = config[:environment]
        # may be needed for vpc_mode
        bootstrap.config[:host_key_verify] = config[:host_key_verify]
        # Modify global configuration state to ensure hint gets set by
        # knife-bootstrap
        Chef::Config[:knife][:hints] ||= {}
        Chef::Config[:knife][:hints]["google"] ||= {}
        bootstrap
      end

      def run
        $stdout.sync = true
        unless @name_args.size > 0
          ui.error("Please provide the name of the new server")
          exit 1
        end

        begin
          zone = client.zones.get(config[:zone] || Chef::Config[:knife][:google_compute_zone]).self_link
        rescue Google::Compute::ResourceNotFound
          ui.error("Zone '#{config[:zone] || Chef::Config[:knife][:google_compute_zone]}' not found")
          exit 1
        rescue Google::Compute::ParameterValidation
          ui.error("Must specify zone in knife config file or in command line as an option. Try --help.")
          exit 1
        end

        begin
          machine_type = client.machine_types.get(:name=>config[:machine_type], :zone=>selflink2name(zone)).self_link
        rescue Google::Compute::ResourceNotFound
          ui.error("MachineType '#{config[:machine_type]}' not found")
          exit 1
        end

        (checked_custom, checked_all) = false
        begin
          image_project = config[:image_project_id]
          machine_type=~Regexp.new('/projects/(.*?)/')
          project = $1
          if image_project.empty?
            unless checked_custom
              checked_custom = true
              ui.info("Looking for Image '#{config[:image]}' in Project '#{project}'")
              image = client.images.get(:project=>project, :name=>config[:image]).self_link
            else
              case config[:image].downcase
              when /debian/
                project = 'debian-cloud'
                ui.info("Looking for Image '#{config[:image]}' in Project '#{project}'")
              when /centos/
                project = 'centos-cloud'
                ui.info("Looking for Image '#{config[:image]}' in Project '#{project}'")
              end
              checked_all = true
              image = client.images.get(:project=>project, :name=>config[:image]).self_link
            end
          else
            checked_all = true
            project = image_project
            image = client.images.get(:project=>project, :name=>config[:image]).self_link
          end
          ui.info("Found Image '#{config[:image]}' in Project '#{project}'")
        rescue Google::Compute::ResourceNotFound
          unless checked_all then
            retry
          else
            ui.error("Image '#{config[:image]}' not found")
            exit 1
          end
        end

        begin
          network = client.networks.get(config[:network]).self_link
        rescue Google::Compute::ResourceNotFound
          ui.error("Network '#{config[:network]}' not found")
          exit 1
        end

        disks = config[:disks].collect{|disk| client.disks.get(:disk=>disk, :zone=>selflink2name(zone)).self_link}
        metadata = config[:metadata].collect{|pair| Hash[*pair.split('=')] }
        network_interface = {'network'=>network}

        if config[:public_ip] == 'EPHEMERAL'
          network_interface.merge!('accessConfigs' =>[{"name"=>"External NAT",
                                  "type"=> "ONE_TO_ONE_NAT"}])
        elsif config[:public_ip] =~ /\d+\.\d+\.\d+\.\d+/
          network_interface.merge!('accessConfigs' =>[{"name"=>"External NAT",
                  "type"=>"ONE_TO_ONE_NAT", "natIP"=>config[:public_ip] }])
        elsif config[:public_ip] == 'NONE'
          # do nothing
        else
          ui.error("Invalid public ip value : #{config[:public_ip]}")
          exit 1
        end
        zone_operation = client.instances.create(:name=>@name_args.first, :zone=>selflink2name(zone),
                                  :image=> image,
                                  :machineType =>machine_type,
                                  :disks=>disks,
                                  :metadata=>{'items'=> metadata },
                                  :networkInterfaces => [network_interface],
                                  :tags=> config[:tags]
                                )

        ui.info("Waiting for the create server operation to complete")
        until zone_operation.progress.to_i == 100
          ui.info(".")
          sleep 1
          zone_operation = client.zoneOperations.get(:name=>zone_operation, :operation=>zone_operation.name, :zone=>selflink2name(zone))
        end
        ui.info("Waiting for the servers to be in running state")

        @instance = client.instances.get(:name=>@name_args.first, :zone=>selflink2name(zone))
        msg_pair("Instance Name", @instance.name)
        msg_pair("MachineType", selflink2name(@instance.machine_type))
        msg_pair("Image", selflink2name(@instance.image))
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
