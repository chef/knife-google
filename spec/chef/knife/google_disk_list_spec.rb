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

describe Chef::Knife::GoogleDiskList do
  let(:knife_plugin) do
    Chef::Knife::GoogleDiskList.new(["-Z"+stored_zone.name])
  end

  it "should enlist all the GCE disks when run invoked" do
    zones = double(Google::Compute::ListableResourceCollection)
    expect(zones).to receive(:get).with(stored_zone.name).
      and_return(stored_zone)
    disks = double(Google::Compute::ListableResourceCollection)
    expect(disks).to receive(:list).with(:zone => stored_zone.name).
      and_return([stored_disk])

    client = double(Google::Compute::Client, :disks => disks, :zones => zones)
    allow(Google::Compute::Client).to receive(:from_json).and_return(client)
    expect(knife_plugin.ui).to receive(:info)
    knife_plugin.run
  end
end
