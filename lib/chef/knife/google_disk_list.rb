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
    class GoogleDiskList < Knife

      include Knife::GoogleBase

      banner "knife google disk list (options)"

      option :gce_zone,
        :short => "-Z ZONE",
        :long => "--gce-zone ZONE",
        :description => "The Zone for disk listing",
        :proc => Proc.new { |key| Chef::Config[:knife][:gce_zone] = key }

      def run
        $stdout.sync = true

        disk_list = [
          ui.color('name', :bold),
          ui.color('zone', :bold),
          ui.color('source image', :bold),
          ui.color('size (GB)', :bold),
          ui.color('status', :bold)].flatten.compact
        output_column_count = disk_list.length

        list_request = true
        parameters = {:project => config[:gce_project], :zone => config[:gce_zone]}

        while list_request
          result = client.execute(
            :api_method => compute.disks.list,
            :parameters => parameters)
          body = MultiJson.load(result.body, :symbolize_keys => true)
          body[:items].each do |disk|
            disk_list << disk[:name]
            disk_list << selflink2name(disk[:zone])
            if disk[:sourceImage].nil?
              disk_list << "-"
            else
              disk_list << selflink2name(disk[:sourceImage])
            end
            disk_list << disk[:sizeGb]
            disk_list << begin
              status = disk[:status].downcase
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
          if body.key?(:nextPageToken)
            parameters = {:project => config[:gce_project],
                          :zone => config[:gce_zone],
                          :pageToken => body[:nextPageToken]}
          else
            list_request = false
          end
        end
        ui.info(ui.list(disk_list, :uneven_columns_across, output_column_count))
      rescue
        raise
      end

    end
  end
end
