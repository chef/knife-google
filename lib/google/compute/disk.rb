# Copyright 2013 Google Inc. All Rights Reserved.
#
# Copyright 2013 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'google/compute/resource'
require 'google/compute/zone'

module Google
  module Compute
    class Disk < Resource

      attr_reader :zone, :size_gb, :status, :options
      attr_reader :source_snapshot, :source_snapshot_id

      def from_hash(disk_data)
        super(disk_data)
        @zone = disk_data["zone"]
        @size_gb = disk_data["sizeGb"]
        @status = disk_data["status"] 
        @options = disk_data["options"]
        @source_snapshot = disk_data["sourceSnapshot"]
        @source_snapshot_id = disk_data["sourceSnapshotId"] 
      end
    end
  end
end
