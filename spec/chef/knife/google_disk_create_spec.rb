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
      [stored_disk.name, "-Z"+stored_zone.name, "-s14"])
  end

  it "#run should invoke compute api to create a disk" do
    zones = double(Google::Compute::ListableResourceCollection)
    zones.should_receive(:get).
      with(stored_zone.name).and_return(stored_zone)
    disks = double(Google::Compute::CreatableResourceCollection)
    disks.should_receive(:create).
      with(:zone => stored_zone.name, :name => stored_disk.name, :sizeGb => "14").
      and_return(stored_zone_operation)
    client = double(Google::Compute::Client, :zones => zones, :disks => disks)
    Google::Compute::Client.stub(:from_json).and_return(client)
    knife_plugin.run
  end
end
