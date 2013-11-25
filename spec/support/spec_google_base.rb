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

require 'spec_helper'
require 'google/compute'

module SpecData
  SPEC_DATA_DIR = File.expand_path('../../data', __FILE__)

  def stored_instance
    @instance ||= Google::Compute::Server.new(load_json("server.json"))
  end

  def stored_global_operation
    @global_operation ||= Google::Compute::GlobalOperation.new(load_json("global_operation.json"))
  end

  def stored_zone_operation
    @zone_operation ||= Google::Compute::ZoneOperation.new(load_json("zone_operation.json"))
  end

  def stored_disk
    @disk ||= Google::Compute::Disk.new(load_json("disk.json"))
  end

  def stored_region
    @region ||= Google::Compute::Region.new(load_json("region.json"))
  end

  def stored_zone
    @zone ||= Google::Compute::Zone.new(load_json("zone.json"))
  end

  def stored_image
    @image ||= Google::Compute::Image.new(load_json("image.json"))
  end

  def stored_machine_type
    @machine_type ||= Google::Compute::MachineType.new(load_json("machine_type.json"))
  end

  def stored_network
    @network ||= Google::Compute::Network.new(load_json 'network.json')
  end

  def load_json file
    MultiJson.load(File.read("#{SPEC_DATA_DIR}/#{file}"))
  end
end
