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
    class GoogleServerList < Knife

      include Knife::GoogleBase

      banner "knife google server list"

      option :gce_zone,
        :short => "-Z ZONE",
        :long => "--gce-zone ZONE",
        :description => "The Zone for server listing",
        :proc => Proc.new { |key| Chef::Config[:knife][:gce_zone] = key }

      def run
        $stdout.sync = true
        instance_list = [
          ui.color('name', :bold),
          ui.color('status', :bold)].flatten.compact
        output_column_count = instance_list.length
        list_request = true
        parameters = {:project => config[:gce_project], :zone => config[:gce_zone]}
        while list_request
          result = client.execute(
            :api_method => compute.instances.list,
            :parameters => parameters)
          body = MultiJson.load(result.body, :symbolize_keys => true)
          body[:items].each do |instance|
            instance_list << instance[:name]
            instance_list << begin
              status = instance[:status].downcase
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
        ui.info(ui.list(instance_list, :uneven_columns_across, output_column_count))
      rescue
        raise
      end

    end
  end
end
