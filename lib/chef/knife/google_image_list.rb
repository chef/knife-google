#
# Author:: Kapil Chouhan (<kapil.chouhan@msystechnologies.com>)
# Copyright:: Copyright (c) 2018-2019 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "chef/knife"
require "chef/knife/cloud/list_resource_command"
require "chef/knife/cloud/google_service"
require "chef/knife/cloud/google_service_helpers"
require "chef/knife/cloud/google_service_options"

class Chef::Knife::Cloud
  class GoogleImageList < ResourceListCommand
    include GoogleServiceHelpers
    include GoogleServiceOptions

    banner "knife google image list"

    def validate_params!
      check_for_missing_config_values!
      super
    end

    def before_exec_command
      @columns_with_info = [
        { label: "NAME", key: "name" },
        { label: "PROJECT", key: "self_link", value_callback: method(:find_project_name) },
        { label: "FAMILY", key: "family" },
        { label: "DISK SIZE", key: "disk_size_gb", value_callback: method(:format_disk_size_value) },
        { label: "STATUS", key: "status" },
      ]
    end

    def find_project_name(self_link)
      self_link[%r{projects\/(.*?)\/}m, 1]
    end

    def format_disk_size_value(disk_size)
      "#{disk_size} GB"
    end

    def query_resource
      service.list_images
    end
  end
end
