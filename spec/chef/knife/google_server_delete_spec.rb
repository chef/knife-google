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
#

require 'spec_helper'

describe Chef::Knife::GoogleServerDelete do
  let(:knife_plugin) do
    Chef::Knife::GoogleServerDelete.new(
      [stored_instance.name, "-Z"+stored_zone.name])
  end

  it "should print out error message if the server is not found" do
    zones = double(Google::Compute::ListableResourceCollection)
    zones.should_receive(:get).with(stored_zone.name).
      and_return(stored_zone)

    instances = double(Google::Compute::DeletableResourceCollection)
    instances.should_receive(:get).
      with(:name => stored_instance.name, :zone => stored_zone.name).
      and_raise(Google::Compute::ResourceNotFound)
    instances.should_not_receive(:delete)

    client = double(Google::Compute::Client,
      :instances => instances, :zones => zones)
    Google::Compute::Client.stub(:from_json).and_return(client)

    knife_plugin.config[:yes] = true
    knife_plugin.ui.should_receive(:error).
      with("Could not locate server '#{stored_zone.name}:#{stored_instance.name}'.")
    knife_plugin.stub(:msg_pair)
    knife_plugin.run
  end

  describe "without purge" do

    it "should invoke api delete method when run is called" do
      zones = double(Google::Compute::ListableResourceCollection)
      zones.should_receive(:get).with(stored_zone.name).
        and_return(stored_zone)

      instances = double(Google::Compute::DeletableResourceCollection)
      instances.should_receive(:get).
        with(:name => stored_instance.name, :zone => stored_zone.name).
        and_return(stored_instance)
      instances.should_receive(:delete).
        with(:instance => stored_instance.name, :zone => stored_zone.name)

      client = double(Google::Compute::Client,
        :zones => zones, :instances => instances)
      Google::Compute::Client.stub(:from_json).and_return(client)
      knife_plugin.ui.should_receive(:warn)
      knife_plugin.config[:yes] = true
      knife_plugin.ui.should_receive(:warn).twice
      knife_plugin.stub(:msg_pair)
      knife_plugin.run
    end
  end

  describe "with purge" do
    it "should invoke api delete method as well as chef objects destroy when run is called" do
      chef_client = double(Chef::ApiClient)
      chef_client.should_receive(:destroy)
      chef_node = double(Chef::Node)
      chef_node.should_receive(:destroy)

      zones = double(Google::Compute::ListableResourceCollection)
      zones.should_receive(:get).with(stored_zone.name).
        and_return(stored_zone)

      instances = double(Google::Compute::DeletableResourceCollection)
      instances.should_receive(:get).
        with(:name => stored_instance.name, :zone => stored_zone.name).
        and_return(stored_instance)
      instances.should_receive(:delete).
        with(:instance => stored_instance.name, :zone => stored_zone.name)

      client = double(Google::Compute::Client,
        :zones => zones, :instances => instances)
      Google::Compute::Client.stub(:from_json).and_return(client)

      knife_plugin.config[:yes] = true
      knife_plugin.config[:purge] = true
      knife_plugin.ui.stub(:warn)
      knife_plugin.stub(:msg_pair)
      Chef::Node.should_receive(:load).with(stored_instance.name).
        and_return(chef_node)
      Chef::ApiClient.should_receive(:load).with(stored_instance.name).
        and_return(chef_client)
      knife_plugin.run
    end
  end
end

describe Chef::Knife::GoogleServerDelete do
  it "should read zone value from knife config file." do
    Chef::Config[:knife][:zone] = stored_zone.name
    knife_plugin = Chef::Knife::GoogleServerDelete.new([stored_instance.name])
    zones = double(Google::Compute::ListableResourceCollection)
    zones.should_receive(:get).with(stored_zone.name).and_return(stored_zone)

    instances = double(Google::Compute::DeletableResourceCollection)
    instances.should_receive(:get).with(:name => stored_instance.name, :zone => stored_zone.name).
        and_return(stored_instance)
    instances.should_receive(:delete).with(:instance => stored_instance.name, :zone => stored_zone.name)

    client = double(Google::Compute::Client, :zones => zones, :instances => instances)
    Google::Compute::Client.stub(:from_json).and_return(client)
    knife_plugin.ui.should_receive(:warn)
    knife_plugin.config[:yes] = true
    knife_plugin.ui.should_receive(:warn).twice
    knife_plugin.stub(:msg_pair)
    knife_plugin.run
  end
end
