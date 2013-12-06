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

describe Chef::Knife::GoogleServerList do
  before(:each) do
    zones = double(Google::Compute::ListableResourceCollection)
    zones.should_receive(:get).with(stored_zone.name).and_return(stored_zone)
    instances = double(Google::Compute::DeletableResourceCollection)
    instances.should_receive(:list).with(:zone => stored_zone.name).and_return([stored_instance])
    client = double(Google::Compute::Client, :instances => instances, :zones => zones)
    Google::Compute::Client.stub(:from_json).and_return(client)
  end

  it "should enlist all the GCE servers when run invoked" do
    knife_plugin = Chef::Knife::GoogleServerList.new(["-Z"+stored_zone.name])
    $stdout.should_receive(:write).with(kind_of(String))
    knife_plugin.run
  end

  it "should list all the GCE servers when zone is set in knife.rb" do
    knife_plugin = Chef::Knife::GoogleServerList.new([Chef::Config[:knife][:gce_zone] = stored_zone.name])
    $stdout.should_receive(:write).with(kind_of(String))
    knife_plugin.run
  end
end
