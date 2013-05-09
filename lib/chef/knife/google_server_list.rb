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

      banner "knife google server list --google-compute-zone ZONE (options)"

      option :zone,
        :short => "-Z ZONE",
        :long => "--google-compute-zone ZONE",
        :description => "The Zone for this server",
        :required => true

      def run
        $stdout.sync = true

        begin
          zone = client.zones.get(config[:zone])
        rescue Google::Compute::ResourceNotFound
          ui.error("Zone '#{config[:zone]}' not found")
          exit 1
        end

        instance_list = [
          ui.color("Name", :bold),
          ui.color('Type', :bold),
          ui.color('Image', :bold),
          ui.color('Public IP', :bold),
          ui.color('Private IP', :bold),
          ui.color('Disks', :bold),
          ui.color("Zone", :bold),
          ui.color('Status', :bold)].flatten.compact

        output_column_count = instance_list.length

        client.instances.list(:zone=>zone.name).each do |instance|
          instance_list << instance.name
          instance_list << selflink2name(instance.machine_type.to_s)
          instance_list << selflink2name(instance.image.to_s)
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
        puts ui.list(instance_list, :uneven_columns_across, output_column_count)
      end
    end
  end
end
