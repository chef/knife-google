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
  class GoogleDiskList < ResourceListCommand
    include GoogleServiceHelpers
    include GoogleServiceOptions

    banner "knife google disk list"

    def validate_params!
      check_for_missing_config_values!
      super
    end

    def before_exec_command
      @columns_with_info = [
        { label: "Zone",         key: "name" },
        { label: "Status",       key: "status", value_callback: method(:format_status_value) },
        { label: "Size (GB)", key: "size_gb" },
        { label: "Type",         key: "type", value_callback: method(:format_disk_type) },
        { label: "Source Image", key: "source_image", value_callback: method(:format_source_image) },
        { label: "Attached To",  key: "users", value_callback: method(:format_users) },
      ]

      @sort_by_field = "name"
    end

    def query_resource
      service.list_disks
    end

    def format_status_value(status)
      status = status.downcase
      status_color = if status == "ready"
                       :green
                     else
                       :red
                     end

      ui.color(status, status_color)
    end

    def format_disk_type(type)
      type.split("/").last
    end

    def format_source_image(source)
      return "unknown" if source.nil? || source.empty?

      source.split("/").last(4).join("/")
    end

    def format_users(users)
      return "none" if users.nil? || users.empty?

      users.map { |user| user.split("/").last(5).join("/") }.join(", ")
    end
  end
end
