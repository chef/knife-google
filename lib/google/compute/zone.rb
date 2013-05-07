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

# Google compute engine, zone resource reference
# https://developers.google.com/compute/docs/reference/v1beta13/zones#resource

module Google
  module Compute
    class Zone < Resource

      attr_reader :maintenance_windows, :available_machine_type, :status
      attr_reader :quotas, :deprecated

      def from_hash(zone_data)
        super(zone_data)
        @status = zone_data["status"] 
        @maintenance_windows = zone_data["maintenanceWindows"]
        @available_machine_type = zone_data["availableMachineType"]
        @quotas = zone_data["quotas"]
        @deprecated = zone_data["deprecated"]
      end
    end
  end
end
