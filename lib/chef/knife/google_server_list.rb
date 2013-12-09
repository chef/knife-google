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
    class GoogleServerList < Knife

      include Knife::GoogleBase

      banner "knife google server list -Z ZONE (options)"

      option :zone,
        :short => "-Z ZONE",
        :long => "--gce-zone ZONE",
        :description => "The Zone for this server"

      def run
        $stdout.sync = true
        
        begin
          zone = client.zones.get(config[:zone] || Chef::Config[:knife][:gce_zone])
        rescue Google::Compute::ResourceNotFound
          ui.error("Zone '#{config[:zone] || Chef::Config[:knife][:gce_zone] }' not found.")
          exit 1
        rescue Google::Compute::ParameterValidation
          ui.error("Must specify zone in knife config file or in command line as an option. Try --help.")
          exit 1
        end

        instance_label = ['name', 'type', 'public ip', 'private ip', 'disks', 'zone', 'status']
        instance_list = (instance_label.map {|label| ui.color(label, :bold)}).flatten.compact

        output_column_count = instance_list.length

        client.instances.list(:zone=>zone.name).each do |instance|
          instance_list << instance.name
          instance_list << selflink2name(instance.machine_type.to_s)
          instance_list << public_ips(instance).join(',')
          instance_list << private_ips(instance).join(',')
          instance_list << disks(instance).join(',')
          instance_list << selflink2name(instance.zone.to_s)
          instance_list << begin
            status = instance.status.downcase
            case status
            when 'stopping', 'stopped', 'terminated'
              ui.color(status, :red)
            when 'requested', 'provisioning', 'staging'
              ui.color(status, :yellow)
            else
              ui.color(status, :green)
            end
          end
        end

        if instance_list.count > 8  # This condition checks if there are any servers available. The first 8 values are the Labels. 
           puts ui.list(instance_list, :uneven_columns_across, output_column_count)
        else
           puts "No servers found in #{zone.name} zone."
        end
      end
    end
  end
end
