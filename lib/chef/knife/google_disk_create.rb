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
require "chef/knife/cloud/command"
require "chef/knife/cloud/google_service"
require "chef/knife/cloud/google_service_helpers"
require "chef/knife/cloud/google_service_options"

class Chef::Knife::Cloud
  class GoogleDiskCreate < Command
    include GoogleServiceHelpers
    include GoogleServiceOptions

    banner "knife google disk create NAME --gce-disk-size N (options)"

    option :disk_size,
      long:        "--gce-disk-size SIZE",
      description: "Size of the persistent disk between 10 and 10000 GB, specified in GB; default is '10' GB",
      default:     10,
      proc:        proc { |size| size.to_i }

    option :disk_type,
      long:        "--gce-disk-type TYPE",
      description: "Disk type to use to create the disk. Possible values are 'pd-standard', 'pd-ssd' and 'local-ssd'; default is 'pd-standard'",
      default:     "pd-standard"

    option :disk_source,
      long:        "--gce-disk-source_image IMAGE_URL",
      description: "GCE disk source image to use when creating disk, such as projects/centos-cloud/global/images/centos-7-v20160216; optional, if not supplied, a blank disk will be created",
      default:     nil

    def validate_params!
      check_for_missing_config_values!(:disk_size, :disk_type)
      raise "Please specify a disk name." unless @name_args.first
      raise "Disk size must be between 10 and 10,000" unless valid_disk_size?(locate_config_value(:disk_size))
      super
    end

    def execute_command
      name = @name_args.first
      size = locate_config_value(:disk_size)
      type = locate_config_value(:disk_type)
      src  = locate_config_value(:disk_source)

      service.create_disk(name, size, type, src)
    end
  end
end
