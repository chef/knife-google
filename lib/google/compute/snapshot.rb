# Copyright 2013 Google Inc. All Rights Reserved.
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

# Google compute engine, snapshot resource reference
# https://developers.google.com/compute/docs/reference/v1beta13/snapshots#resource

module Google
  module Compute
    class Snapshot < Resource

      attr_reader :disk_size_gb, :status, :source_disk, :source_disk_id

      def from_hash(data)
        super(data)
        @disk_size_gb = data["diskSizeGb"]
        @status = data["status"]
        @source_disk = data["sourceDisk"]
        @source_disk_id = data["sourceDiskId"]
      end
    end
  end
end
