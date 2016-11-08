# frozen_string_literal: true
#
# Author:: Paul Rossman (<paulrossman@google.com>)
# Author:: Chef Partner Engineering (<partnereng@chef.io>)
# Copyright:: Copyright 2015-2016 Google Inc., Chef Software, Inc.
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

require "chef/knife"
require "chef/knife/cloud/list_resource_command"
require "chef/knife/cloud/google_service"
require "chef/knife/cloud/google_service_helpers"
require "chef/knife/cloud/google_service_options"

class Chef::Knife::Cloud
  class GoogleRegionQuotas < Command
    include GoogleServiceHelpers
    include GoogleServiceOptions

    banner "knife google region quotas"

    def validate_params!
      check_for_missing_config_values!
      super
    end

    def execute_command
      service.list_regions.each do |region|
        ui.msg(ui.color("Region: #{region.name}", :bold))

        quotas = region.quotas
        if quotas.nil? || quotas.empty?
          ui.warn("No quota information available for this region.")
          ui.msg("")
          next
        end

        output = []
        output << table_header
        quotas.each do |quota|
          output << format_name(quota.metric)
          output << format_number(quota.limit)
          output << format_number(quota.usage)
        end

        ui.msg(ui.list(output.flatten, :uneven_columns_across, table_header.size))
        ui.msg("")
      end
    end

    def table_header
      [
        ui.color("Quota", :bold),
        ui.color("Limit", :bold),
        ui.color("Usage", :bold),
      ]
    end

    def format_name(name)
      name.split("_").map { |x| x.capitalize }.join(" ")
    end

    def format_number(number)
      number % 1 == 0 ? number.to_i.to_s : number.to_s
    end
  end
end
