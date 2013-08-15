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

describe Chef::Knife::GoogleDiskDelete do

  let(:knife_plugin) do
    Chef::Knife::GoogleDiskDelete.new([stored_disk.name, "-Z"+stored_zone.name])
  end

  it "should print out error message if the disk is not found" do
    zones = double(Google::Compute::ListableResourceCollection)
    zones.should_receive(:get).with(stored_zone.name).
      and_return(stored_zone)
    disks = double(Google::Compute::DeletableResourceCollection)
    disks.should_receive(:get).
      with(:zone=>stored_zone.name, :disk=>stored_disk.name).
      and_raise(Google::Compute::ResourceNotFound)
    disks.should_not_receive(:delete)
    client = double(Google::Compute::Client,
      :disks=>disks, :zones=>zones)
    Google::Compute::Client.stub(:from_json).and_return(client)

    knife_plugin.config[:yes] = true
    knife_plugin.ui.should_receive(:error).
      with("Disk '#{stored_zone.name}:#{stored_disk.name}' not found")
    knife_plugin.stub(:msg_pair)
    expect {
      knife_plugin.run
    }.to raise_error(SystemExit)
  end

  it "should invoke api delete method when run is called" do
    zones = double(Google::Compute::ListableResourceCollection)
    zones.should_receive(:get).with(stored_zone.name).
      and_return(stored_zone)
    disks = double(Google::Compute::DeletableResourceCollection)
    disks.should_receive(:get).
      with(:zone=>stored_zone.name, :disk=>stored_disk.name).
      and_return(stored_disk)
    disks.should_receive(:delete).
      with(:zone=>stored_zone.name, :disk=>stored_disk.name)
    client = double(Google::Compute::Client,
      :zones=>zones,:disks=>disks)
    Google::Compute::Client.stub(:from_json).
      and_return(client)
    knife_plugin.config[:yes] = true
    knife_plugin.ui.should_receive(:warn).
      with("Disk '#{stored_zone.name}:#{stored_disk.name}' deleted")
    knife_plugin.stub(:msg_pair)
    knife_plugin.run
  end
end
