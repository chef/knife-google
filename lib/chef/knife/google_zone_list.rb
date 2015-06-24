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
    class GoogleZoneList < Knife

      include Knife::GoogleBase

      banner "knife google zone list"

      def run
        $stdout.sync = true
        zones_list = [
          ui.color('name', :bold),
          ui.color('status', :bold)].flatten.compact
        output_column_count = zones_list.length
        result = client.execute(
          :api_method => compute.zones.list,
          :parameters => {:project => config[:gce_project]})
        body = MultiJson.load(result.body, :symbolize_keys => true)
        body[:items].each do |item|
          zones_list << item[:name]
          zones_list << begin
            status = item[:status].downcase
            case status
            when 'up'
              ui.color(status, :green)
            else
              ui.color(status, :red)
            end
          end
        end
        ui.info(ui.list(zones_list, :uneven_columns_across, output_column_count))
      end

    end
  end
end
