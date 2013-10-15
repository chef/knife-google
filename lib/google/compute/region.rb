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

module Google
  module Compute
    class Region < Resource

      attr_reader :status, :zones
      attr_reader :quotas, :deprecated

      def from_hash(region_data)
        super(region_data)
        @status = region_data["status"] 
        @zones = region_data["zones"]
        @quotas = region_data["quotas"]
        @deprecated = region_data["deprecated"]
      end
    end
  end
end
