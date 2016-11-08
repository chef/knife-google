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
require "chef/knife/cloud/server/list_command"
require "chef/knife/cloud/server/list_options"
require "chef/knife/cloud/google_service"
require "chef/knife/cloud/google_service_helpers"
require "chef/knife/cloud/google_service_options"

class Chef::Knife::Cloud
  class GoogleServerList < ServerListCommand
    include GoogleServiceHelpers
    include GoogleServiceOptions

    banner "knife google server list"

    def validate_params!
      check_for_missing_config_values!
      super
    end

    def before_exec_command
      @columns_with_info = [
        { label: "Instance Name", key: "name" },
        { label: "Status",        key: "status", value_callback: method(:format_status_value) },
        { label: "Machine Type",  key: "machine_type" },
        { label: "Internal IP",   key: "private_ip" },
        { label: "External IP",   key: "public_ip" },
        { label: "Network",       key: "network" },
      ]

      @sort_by_field = "name"
    end

    def format_status_value(status)
      status = status.downcase
      status_color = case status
                     when "stopping", "stopped", "terminated"
                       :red
                     when "requested", "provisioning", "staging"
                       :yellow
                     else
                       :green
                     end

      ui.color(status, status_color)
    end
  end
end
