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

require 'spec_helper'

describe Chef::Knife::GoogleDiskCreate do
  let(:knife_plugin) do
    Chef::Knife::GoogleDiskCreate.new(
      [stored_disk.name, "-Z"+stored_zone.name])
  end

  it "#run should invoke compute api to create a disk" do
    zones = double(Google::Compute::ListableResourceCollection)
    expect(zones).to receive(:get).
      with(stored_zone.name).and_return(stored_zone)
    disks = double(Google::Compute::CreatableResourceCollection)
    expect(disks).to receive(:create).
      with(:name => stored_disk.name, :sizeGb => 10, :zone => stored_zone.name,:type=>"").
      and_return(stored_zone_operation)
    disk_type = double(Google::Compute::CreatableResourceCollection)
    d_type = Object.new
    d_type.define_singleton_method(:self_link){""}
    expect(disk_type).to receive(:get).
      with(:name => 'pd-ssd', :zone => stored_zone.name).
      and_return(d_type)
    client = double(Google::Compute::Client, :zones => zones, :disks => disks, :disk_types => disk_type)
    allow(Google::Compute::Client).to receive(:from_json).and_return(client)
    knife_plugin.config[:disk_size] = 10
    knife_plugin.config[:disk_type] = 'pd-ssd'
    knife_plugin.run
  end
end
