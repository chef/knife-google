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

require 'chef/knife/google_base'

class Chef
  class Knife
    class GoogleServerDelete < Knife

      include Knife::GoogleBase

      deps do
        require 'google/compute'
      end

      banner "knife google server delete SERVER [SERVER] --google-compute-zone ZONE (options)"

      attr_reader :instances

      option :zone,
        :short => "-Z ZONE",
        :long => "--google-compute-zone ZONE",
        :description => "The Zone for this server",
        :required => true

      option :purge,
        :short => "-P",
        :long => "--purge",
        :boolean => true,
        :default => false,
        :description => "Destroy corresponding node and client on the Chef Server, in addition to destroying the GCE server itself.  Assumes node and client have the same name as the server (if not, add the '--node-name' option)."

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The name of the node and client to delete, if it differs from the server name.  Only has meaning when used with the '--purge' option."

      # Taken from knife-ec2 plugin, for rational , check the following link
      # https://github.com/opscode/knife-ec2/blob/master/lib/chef/knife/ec2_server_delete.rb#L48
      def destroy_item(klass, name, type_name)
        begin
          object = klass.load(name)
          object.destroy
          ui.warn("Deleted #{type_name} #{name}")
        rescue Net::HTTPServerException
          ui.warn("Could not find a #{type_name} named #{name} to delete!")
        end
      end

      def run
        begin
          zone = client.zones.get(config[:zone]).self_link
        rescue Google::Compute::ResourceNotFound
          ui.error("Zone '#{config[:zone]}' not found")
          exit 1
        end

        @instances = []
        @name_args.each do |instance_name|
          begin
            instance = client.instances.get(:name=>instance_name, :zone=>selflink2name(zone))
            @instances << instance
            msg_pair("Name", instance.name)
            msg_pair("MachineType", selflink2name(instance.machine_type))
            msg_pair("Image", selflink2name(instance.image))
            msg_pair("Zone", selflink2name(instance.zone))
            msg_pair("Tags", instance.tags.has_key?("items") ? instance.tags["items"].join(',') : "None")
            msg_pair("Public IP Address", public_ips(instance).join(','))
            msg_pair("Private IP Address", private_ips(instance).join(','))

            puts "\n"
            ui.confirm("Do you really want to delete server '#{selflink2name(zone)}:#{instance.name}'")

            client.instances.delete(:instance=>instance.name, :zone=>selflink2name(zone))

            ui.warn("Deleted server '#{selflink2name(zone)}:#{instance.name}'")

            if config[:purge]
              thing_to_delete = config[:chef_node_name] || instance.name
              destroy_item(Chef::Node, thing_to_delete, "node")
              destroy_item(Chef::ApiClient, thing_to_delete, "client")
            else
              ui.warn("Corresponding node and client for the #{instance.name} server  were not deleted and remain registered with the Chef Server")
            end
          rescue
            ui.error("Could not locate server '#{selflink2name(zone)}:#{instance_name}'.")
          end
        end
      end
    end
  end
end
