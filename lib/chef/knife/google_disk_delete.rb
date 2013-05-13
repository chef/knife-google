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
    class GoogleDiskDelete < Knife

      include Knife::GoogleBase

      banner "knife google disk delete NAME --google-compute-zone ZONE"

      deps do
        require 'google/compute'
      end

      option :zone,
        :short => "-Z ZONE",
        :long => "--google-compute-zone ZONE",
        :description => "The Zone for this disk",
        :required => true

      def run
        unless @name_args.size > 0
          ui.error("Please provide the name of the disk to be deleted")
          exit 1
        end

        begin
          zone = client.zones.get(config[:zone])
        rescue Google::Compute::ResourceNotFound
          ui.error("Zone '#{config[:zone]}' not found")
          exit 1
        end

        begin
          disk = client.disks.get(:zone=>zone.name, :disk=>@name_args.first)
          ui.confirm("Are you sure you want to delete disk '#{zone.name}:#{disk.name}'")
          zone_operation = client.disks.delete(:zone=>zone.name, :disk=>disk.name)
          ui.warn("Disk '#{zone.name}:#{disk.name}' deleted")
        rescue Google::Compute::ResourceNotFound
          ui.error("Disk '#{zone.name}:#{@name_args.first}' not found")
          exit 1
        end
      end
    end
  end
end
