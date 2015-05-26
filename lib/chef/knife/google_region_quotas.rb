# Copyright 2015 Google Inc. All Rights Reserved.
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
    class GoogleRegionQuotas < Knife

      include Knife::GoogleBase

      banner "knife google region quotas"

      def run
        $stdout.sync = true

        quotas_list = [
          ui.color('region', :bold),
          ui.color('quota', :bold),
          ui.color('limit', :bold),
          ui.color('usage', :bold)].flatten.compact

        output_column_count = quotas_list.length

        result = client.execute(
          :api_method => compute.regions.list,
          :parameters => {:project => config[:gce_project]})

        body = MultiJson.load(result.body, :symbolize_keys => true)

        body[:items].each do |item|
          region = item[:name]
          item[:quotas].each do |quota|
            quotas_list << region
            quotas_list << quota[:metric].downcase
            quotas_list << quota[:limit].to_s
            quotas_list << quota[:usage].to_s
          end
        end

        ui.info(ui.list(quotas_list, :uneven_columns_across, output_column_count))
      end
    end
  end
end
