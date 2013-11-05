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
    class GoogleRegionList < Knife

      include Knife::GoogleBase

      banner "knife google region list (options)"

      option :limits,
        :short => "-L",
        :long => "--with-limits",
        :description => "Additionally print the quota limit for each metric",
        :required => false,
        :boolean => true,
        :default => false 

      def run
        $stdout.sync = true

        region_list = [
          ui.color("name", :bold),
          ui.color('status', :bold),
          ui.color('deprecation', :bold),
          ui.color('cpus', :bold),
          ui.color('disks-total-gb', :bold),
          ui.color('in-use-addresses', :bold),
          ui.color('static-addresses', :bold)].flatten.compact

        output_column_count = region_list.length

        client.regions.list.each do |region|
          region_list << region.name
          region_list << begin
            status = region.status.downcase
            case status
            when 'up'
              ui.color(status, :green)
            else
              ui.color(status, :red)
            end
          end
          deprecation_state = "-"
          if region.deprecated.respond_to?('state')
            deprecation_state = region.deprecated.state
          end
          region_list << deprecation_state
          cpu_usage = "0"
          cpu_limit = "0"
          region.quotas.each do |quota|
            if quota["metric"] == "CPUS"
              cpu_usage = "#{quota["usage"].to_i}"
              cpu_limit = "#{quota["limit"].to_i}"
            end
          end
          if config[:limits] == true
            cpu_quota = "#{cpu_usage}/#{cpu_limit}"
          else
            cpu_quota = "#{cpu_usage}"
          end
          region_list << cpu_quota
          disk_usage = "0"
          disk_limit = "0"
          region.quotas.each do |quota|
            if quota["metric"] == "DISKS_TOTAL_GB"
              disk_usage = "#{quota["usage"].to_i}"
              disk_limit = "#{quota["limit"].to_i}"
            end
          end
          if config[:limits] == true
            disk_quota = "#{disk_usage}/#{disk_limit}" 
          else
            disk_quota = "#{disk_usage}"
          end
          region_list << disk_quota
          inuse_usage = "0"
          inuse_limit = "0"
          region.quotas.each do |quota|
            if quota["metric"] == "IN_USE_ADDRESSES"
             inuse_usage = "#{quota["usage"].to_i}"
             inuse_limit = "#{quota["limit"].to_i}"
            end
          end
          if config[:limits] == true
            inuse_quota = "#{inuse_usage}/#{inuse_limit}"
          else
            inuse_quota = "#{inuse_usage}"
          end
          region_list << inuse_quota
          static_usage = "0"
          static_limit = "0"
          region.quotas.each do |quota|
            if quota["metric"] == "STATIC_ADDRESSES"
              static_usage = "#{quota["usage"].to_i}"
              static_limit = "#{quota["limit"].to_i}"
            end
          end
          if config[:limits] == true
            static_quota = "#{static_usage}/#{static_limit}"
          else
            static_quota = "#{static_usage}"
          end
          region_list << static_quota
        end
        ui.info(ui.list(region_list, :uneven_columns_across, output_column_count))
      end
    end
  end
end
