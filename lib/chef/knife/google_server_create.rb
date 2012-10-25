# Author:: Chirag Jog (<chiragj@websym.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

      deps do
        require 'readline'
        require 'chef/knife/bootstrap'
        require 'highline'
        require 'net/ssh/multi'
        require 'net/scp'
        require 'tempfile'
        Chef::Knife::Bootstrap.load_deps
      end

      include Knife::GoogleBase

      banner "knife google server create NAME [RUN LIST...] (options)"

      option :run_list,
        :short => "-r RUN_LIST",
        :long => "--run-list RUN_LIST",
        :description => "Comma separated list of roles/recipes to apply",
        :proc => lambda { |o| o.split(/[\s,]+/) },
        :default => []

      option :availability_zone,
        :short => "-Z ZONE",
        :long => "--availability-zone ZONE",
        :description => "The Availability Zone",
        :default => "us-east1-a",
        :proc => Proc.new { |key| Chef::Config[:knife][:availability_zone] = key }

      option :distro,
        :short => "-d DISTRO",
        :long => "--distro DISTRO",
        :description => "Bootstrap a distro using a template; default is 'ubuntu10.04-gems'",
        :proc => Proc.new { |d| Chef::Config[:knife][:distro] = d },
        :default => "ubuntu10.04-gems"

      option :template_file,
        :long => "--template-file TEMPLATE",
        :description => "Full path to location of template to use",
        :proc => Proc.new { |t| Chef::Config[:knife][:template_file] = t },
        :default => false

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The Chef node name for your new node",
        :proc => Proc.new { |t| Chef::Config[:knife][:chef_node_name] = t }

      option :ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The ssh username; default is 'ubuntu'",
        :default => "ubuntu"

      option :server_name,
        :short => "-s NAME",
        :long => "--server-name NAME",
        :description => "The server name",
        :proc => Proc.new { |server_name| Chef::Config[:knife][:server_name] = server_name } 

      option :flavor,
        :short => "-f FLAVOR",
        :long => "--flavor FLAVOR",
        :description => "The flavor of server (standard-1-cpu,standard-2-cpu-ephemeral-disk, etc)",
        :proc => Proc.new { |f| Chef::Config[:knife][:flavor] = f },
        :default => "standard-1-cpu"

      option :image,
        :short => "-I IMAGE",
        :long => "--google-image IMAGE",
        :description => "Your google Image resource name",
        :proc => Proc.new { |template| Chef::Config[:knife][:image] = template }
        
      option :private_key_file,
        :short => "-i PRIVATE_KEY_FILE",
        :long => "--private-key-file PRIVATE_KEY_FILE",
        :description => "The SSH private key file used for authentication",
        :proc => Proc.new { |identity| Chef::Config[:knife][:private_key_file] = identity } 
 
      option :public_key_file,
        :short => "-k PUBLIC_KEY_FILE",
        :long => "--public-key-file PUBLIC_KEY_FILE",
        :description => "The SSH public key file used for authentication",
        :proc => Proc.new { |identity| Chef::Config[:knife][:public_key_file] = identity } 
 
      option :network,
        :short => "-n NETWORKNAME",
        :long => "--network NETWORKNAME",
        :description => "The Network in which to create the Virtual machine",
        :proc => Proc.new { |network| Chef::Config[:knife][:network] = network},
        :default => "default"

      option :external_ip_address,
        :short => "-e IPADDRESS",
        :long => "--external-ip-address IPADDRESS",
        :description => "A Static IP provided by Google",
        :proc => Proc.new { |ipaddr| Chef::Config[:knife][:external_ip_address] = ipaddr},
        :default => "ephemeral"

      option :internal_ip_address,
        :short => "-P IPADDRESS",
        :long => "--internal-ip-address IPADDRESS",
        :description => "A Static IP provided by Google",
        :proc => Proc.new { |ipaddr| Chef::Config[:knife][:internal_ip_address] = ipaddr}

      option :project,
        :short => "-p PROJECT",
        :long => "--project PROJECT",
        :description => "Google Compute Project",
        :proc => Proc.new { |project| Chef::Config[:knife][:google_project] = project}

      def h
        @highline ||= HighLine.new
      end
      
      def locate_config_value(key)
        key = key.to_sym
        config[key] || Chef::Config[:knife][key]
      end

      def tcp_test_ssh(hostname, port)
        tcp_socket = TCPSocket.new(hostname, port)
        readable = IO.select([tcp_socket], nil, nil, 5)
        if readable
          Chef::Log.debug("sshd accepting connections on #{hostname}, banner is #{tcp_socket.gets}")
          yield
          true
        else
          false
        end
      rescue Errno::ETIMEDOUT
        false
      rescue Errno::EPERM
        false
      rescue Errno::ECONNREFUSED
        sleep 2
        false
      rescue Errno::EHOSTUNREACH
        sleep 2
        false
      ensure
        tcp_socket && tcp_socket.close
      end

      def run
        unless Chef::Config[:knife][:server_name]
          ui.error("Server Name is a compulsory parameter")
          exit 1
        end

        unless Chef::Config[:knife][:public_key_file]
          ui.error("SSH public key file is a compulsory parameter")
          exit 1
        end

        unless Chef::Config[:knife][:google_project]
          ui.error("Project ID is a compulsory parameter")
          exit 1
        end

        $stdout.sync = true

        project_id = Chef::Config[:knife][:google_project]
        validate_project(project_id)

        server_name = Chef::Config[:knife][:server_name]
        image = Chef::Config[:knife][:image]
        key_file = locate_config_value(:public_key_file)
        network = locate_config_value(:network)
        flavor = locate_config_value(:flavor)
        zone = locate_config_value(:availability_zone)
        user = locate_config_value(:ssh_user)
        external_ip_address = locate_config_value(:external_ip_address)
        internal_ip_address = locate_config_value(:internal_ip_address) || nil
        puts "\n#{ui.color("Waiting for the server to be Instantiated", :magenta)}"
        cmd_add_instance = "#{@gcompute} addinstance #{server_name} --machine_type #{flavor} " +
                             "--zone #{zone} --project #{project_id} --tags #{server_name} " +
                             "--authorized_ssh_keys #{user}:#{key_file} --network #{network} " +
                             "--external_ip_address #{external_ip_address} --print_json"
        cmd_add_instance << " --internal_ip_address #{internal_ip_address}" if internal_ip_address 
        cmd_add_instance << " --image=#{image}" if image

        Chef::Log.debug 'Executing ' +  cmd_add_instance
        create_server = exec_shell_cmd(cmd_add_instance)

        if create_server.stderr.downcase.scan("error").size > 0
          ui.error("\nFailed to create server: #{create_server.stderr}")
          exit 1
        end
        if create_server.stdout.downcase.scan("error").size > 0
          begin
            output = to_json(create_server.stdout)["items"][0]["error"]
          rescue
            output = create_server.stdout
          end
          ui.error("\nFailed to create server: #{output}")
          exit 1
        end
                    
        #Fetch server information
        cmd_get_instance  = "#{@gcompute} getinstance #{server_name} --project_id #{project_id} --print_json "
        Chef::Log.debug 'Executing ' +  cmd_get_instance
        get_instance = exec_shell_cmd(cmd_get_instance)

        if not get_instance.stderr.downcase.scan("error").empty?
          ui.error("Failed to fetch server details.")
          exit 1
        end

        server = to_json(get_instance.stdout)
        private_ip = []
        public_ip = []
        server["networkInterfaces"].each do  |interface| 
          private_ip << interface["networkIP"]
          interface["accessConfigs"].select { |cfg| public_ip << cfg["natIP"] }
        end

        puts "#{ui.color("Public IP Address", :cyan)}: #{public_ip[0]}"
        puts "#{ui.color("Private IP Address", :cyan)}: #{private_ip[0]}"
        puts "\n#{ui.color("Waiting for sshd.", :magenta)}"
        puts(".") until tcp_test_ssh(public_ip[0], "22") { sleep @initial_sleep_delay ||= 10; puts("done") }
        puts "\nBootstrapping #{h.color(server_name, :bold)}..."
        bootstrap_for_node(server_name, public_ip[0]).run
      end

      def bootstrap_for_node(server_name, public_ip)
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args = [public_ip]
        bootstrap.config[:run_list] = locate_config_value(:run_list)
        bootstrap.config[:ssh_user] = locate_config_value(:ssh_user) || "root"
        bootstrap.config[:identity_file] = locate_config_value(:private_key_file)
        bootstrap.config[:chef_node_name] = locate_config_value(:chef_node_name) || server_name
        bootstrap.config[:distro] = locate_config_value(:distro)
        bootstrap.config[:bootstrap_version] = locate_config_value(:bootstrap_version)
        bootstrap.config[:use_sudo] = true unless config[:ssh_user] == 'root'
        bootstrap.config[:template_file] = locate_config_value(:template_file)
        bootstrap
      end
    end
  end
end
