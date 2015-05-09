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
require 'chef/knife/google_base'

class Chef
  class Knife
    class GoogleDiskCreate < Knife

      include Knife::GoogleBase

      banner "knife google disk create NAME --gce-disk-size N (options)"

      option :gce_zone,
        :short => "-Z ZONE",
        :long => "--gce-zone ZONE",
        :description => "The Zone for this disk",
        :proc => Proc.new { |key| Chef::Config[:knife][:gce_zone] = key }

      option :disk_size,
        :long => "--gce-disk-size SIZE",
        :description => "Size of the persistent disk between 1 and 10000 GB, specified in GB; default is '10' GB",
        :default => "10"

      option :disk_type,
        :long => "--gce-disk-type TYPE",
        :description => "Disk type to use to create the disk. Possible values are pd-standard, pd-ssd and local-ssd",
        :default => "pd-standard"

      def run
        $stdout.sync = true
        unless @name_args.size > 0
          ui.error("Please provide the name of the new disk")
          raise
        end

        disk_size = config[:disk_size].to_i

        unless disk_size.between?(1, 10000)
          ui.error("Size of the persistent disk must be between 1 and 10000 GB.")
          raise
        end

        disk_type = "zones/#{config[:zone]}/diskTypes/#{config[:disk_type]}"

        begin
          result = client.execute(
            :api_method => compute.disks.insert,
            :parameters => {:project => config[:gce_project], :zone => config[:gce_zone]},
            :body_object => {:name => config[:name], :sizeGb => disk_size, :type => disk_type})
          body = MultiJson.load(result.body, :symbolize_keys => true)
          raise "#{body[:error][:message]}" if result.status != 200
        rescue => e
          ui.error(e)
          raise
        end

      end

    end
  end
end
