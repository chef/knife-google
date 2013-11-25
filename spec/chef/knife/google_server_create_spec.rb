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

describe Chef::Knife::GoogleServerCreate do
  before(:each) do
    zones = double(Google::Compute::ListableResourceCollection)
    zones.should_receive(:get).with(stored_zone.name).
      and_return(stored_zone)

    machine_types = double(Google::Compute::ListableResourceCollection)
    machine_types.should_receive(:get).
      with({:name => stored_machine_type.name, :zone => stored_zone.name}).
      and_return(stored_machine_type)

    images = double(Google::Compute::ListableResourceCollection)
    images.should_receive(:get).
      with({:project => "debian-cloud", :name => stored_image.name}).
      and_return(stored_image)

    networks = double(Google::Compute::ListableResourceCollection)
    networks.should_receive(:get).with(stored_network.name).
      and_return(stored_network)

    instances = double(Google::Compute::ListableResourceCollection)
    instances.should_receive(:create).with(
      {:name => stored_instance.name, :image => stored_image.self_link,
      :machineType => stored_machine_type.self_link, :disks => [],
      :metadata => {"items" => []}, :zone => stored_zone.name,
      :networkInterfaces => [
        {"network" => stored_network.self_link,
        "accessConfigs" => [
          {"name" => "External NAT", "type" => "ONE_TO_ONE_NAT"}]}],
      :serviceAccounts => [
        {"kind" => "compute#serviceAccount",
        "email" => "123845678986@project.gserviceaccount.com",
        "scopes" => [
          "https://www.googleapis.com/auth/userinfo.email",
          "https://www.googleapis.com/auth/compute",
          "https://www.googleapis.com/auth/devstorage.full_control"]}],
      :tags => nil}).and_return(stored_zone_operation)

    instances.should_receive(:get).
      with(:zone => stored_zone.name, :name => stored_instance.name).
      and_return(stored_instance)

    client = double(Google::Compute::Client, :instances => instances,
      :images => images, :zones => zones,:machine_types => machine_types,
      :networks => networks)
    Google::Compute::Client.stub(:from_json).and_return(client)
  end

  it "#run should invoke compute api to create an server with a service account" do
    knife_plugin = Chef::Knife::GoogleServerCreate.new([
      "-m"+stored_machine_type.name,
      "-I"+stored_image.name,
      "-J"+"debian-cloud",
      "-n"+stored_network.name,
      "-Z"+stored_zone.name, 
      "-S"+"https://www.googleapis.com/auth/userinfo.email,https://www.googleapis.com/auth/compute,https://www.googleapis.com/auth/devstorage.full_control",
      "-s"+"123845678986@project.gserviceaccount.com",
      stored_instance.name])
    knife_plugin.config[:disks]=[]
    knife_plugin.config[:metadata]=[]
    knife_plugin.config[:public_ip]='EPHEMERAL'
    knife_plugin.ui.stub(:info)

    knife_plugin.stub(:wait_for_sshd)
    knife_plugin.should_receive(:bootstrap_for_node).
      with(stored_instance,'10.100.0.10').
      and_return(double("Chef::Knife::Bootstrap",:run => true))

    knife_plugin.run
  end

  it "should read zone value from knife config file." do
    Chef::Config[:knife][:google_compute_zone] = stored_zone.name
    knife_plugin = Chef::Knife::GoogleServerCreate.new(["-m"+stored_machine_type.name,
      "-I"+stored_image.name,
      "-J"+"debian-cloud",
      "-S"+"https://www.googleapis.com/auth/userinfo.email,https://www.googleapis.com/auth/compute,https://www.googleapis.com/auth/devstorage.full_control",
      "-s"+"123845678986@project.gserviceaccount.com",
      "-n"+stored_network.name,
       stored_instance.name])
    knife_plugin.config[:disks]=[]
    knife_plugin.config[:metadata]=[]
    knife_plugin.config[:public_ip]='EPHEMERAL'
    knife_plugin.ui.stub(:info)

    knife_plugin.stub(:wait_for_sshd)
    knife_plugin.should_receive(:bootstrap_for_node).
      with(stored_instance, '10.100.0.10').
      and_return(double("Chef::Knife::Bootstrap", :run => true))
    knife_plugin.run
  end
end

describe "without appropriate command line options" do
  it "should throw exception when required params are not passed" do
    $stdout.stub(:write) # lets not print those error messages
    expect {
      Chef::Knife::GoogleServerCreate.new([ "NAME"])
    }.to raise_error(SystemExit)
  end
end
