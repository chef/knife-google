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
require 'time'

class Chef
  class Knife
    class GoogleZoneList < Knife

      include Knife::GoogleBase

      banner "knife google zone list (options)"

      def run
        $stdout.sync = true

        zone_list = [
          ui.color("Name", :bold),
          ui.color('Status', :bold),
          ui.color('Servers', :bold),
          ui.color('Disks', :bold),
          ui.color('Maintainance Window',:bold)].flatten.compact

        output_column_count = zone_list.length

        client.zones.list.each do |zone|
          zone_list << zone.name
          zone_list << begin
            status = zone.status.downcase
            case status
            when 'up'
              ui.color(status, :green)
            else
              ui.color(status, :red)
            end
          end
          instance_quota = "0"
          zone.quotas.each do |quota|
            if quota["metric"] == "INSTANCES"
              instance_quota = "#{quota["usage"].to_i}"
            end
          end
          zone_list << instance_quota
          disk_quota = "0"
          zone.quotas.each do |quota|
            if quota["metric"] == "DISKS"
              disk_quota = "#{quota["usage"].to_i}"
            end
          end
          zone_list << disk_quota
          maintenance_window = zone.maintenance_windows.map do |mw|
            begin_time = Time.parse(mw["beginTime"])
            end_time = Time.parse(mw["endTime"])
            if (Time.now >= begin_time) and (Time.now <= end_time)
              ui.color("#{begin_time} to #{end_time}",:red)
            else
              ui.color("#{begin_time} to #{end_time}",:green)
            end
          end.join(",")
          zone_list << maintenance_window
        end
        ui.info(ui.list(zone_list, :uneven_columns_across, output_column_count))
      end
    end
  end
end
