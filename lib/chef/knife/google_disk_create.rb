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

class Chef
  class Knife
    class GoogleDiskCreate < Knife

      include Knife::GoogleBase

      banner "knife google disk create NAME --gce-disk-size N -Z ZONE (options)"

      deps do
        require 'google/compute'
      end

      option :zone,
        :short => "-Z ZONE",
        :long => "--gce-zone ZONE",
        :description => "The Zone for this disk",
        :required => true

      option :disk_size,
        :long => "--gce-disk-size SIZE",
        :description => "Size of the persistent disk between 1 and 10000 GB, specified in GB; default is '1' GB",
        :default => "10"

      def run
        $stdout.sync = true
        unless @name_args.size > 0
          ui.error("Please provide the name of the new disk")
          exit 1
        end

        begin
          zone = client.zones.get(config[:zone])
        rescue Google::Compute::ResourceNotFound
          ui.error("Zone '#{config[:zone]}' not found")
          exit 1
        end

        begin
          disk_size = config[:disk_size].to_i
          raise if !disk_size.between?(1, 10000)
        rescue
          ui.error("Size of the persistent disk must be between 1 and 10000 GB.")
          exit 1
        end

        zone_operation = client.disks.create(:name => @name_args.first,
                                             :sizeGb => config[:disk_size],
                                             :zone => zone.name)
      end
    end
  end
end
