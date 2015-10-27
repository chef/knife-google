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
    class GoogleDiskList < Knife

      include Knife::GoogleBase

      banner "knife google disk list -Z ZONE (options)"

      option :gce_zone,
        :short => "-Z ZONE",
        :long => "--gce-zone ZONE",
        :description => "The Zone for disk listing"

      def run
        $stdout.sync = true

        begin
          zone = client.zones.get(locate_config_value(:gce_zone))
        rescue Google::Compute::ResourceNotFound
          ui.error("Zone '#{locate_config_value(:gce_zone)}' not found")
          exit 1
        end

        disk_list = [
          ui.color("name", :bold),
          ui.color('zone', :bold),
          ui.color('source snapshot', :bold),
          ui.color('size (in GB)', :bold),
          ui.color('status', :bold)].flatten.compact

        output_column_count = disk_list.length

        client.disks.list(:zone=>zone.name).each do |disk|
          disk_list << disk.name
          disk_list << selflink2name(disk.zone)
          if disk.source_snapshot.nil?
            disk_list << " "
          else
            disk_list << selflink2name(disk.source_snapshot)
          end
          disk_list << disk.size_gb
          disk_list << begin
            status = disk.status.downcase
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
        ui.info(ui.list(disk_list, :uneven_columns_across, output_column_count))
      end
    end
  end
end
