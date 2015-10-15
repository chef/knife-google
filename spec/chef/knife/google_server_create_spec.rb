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
    @server_instance = Chef::Knife::GoogleServerCreate.new([
      "-m"+stored_machine_type.name,
      "-I"+stored_image.name,
      "-n"+stored_network.name,
      "-Z"+stored_zone.name,
      stored_instance.name])
    @server_instance.config[:service_account_scopes]=["https://www.googleapis.com/auth/userinfo.email","https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.full_control"]
    @server_instance.config[:service_account_name]='123845678986@project.gserviceaccount.com'
    @server_instance.config[:boot_disk_size]='10'
    @server_instance.config[:metadata]=[]
    @server_instance.config[:metadata_from_file]=[]
    @server_instance.config[:tags]=[]

    @instances = double(Google::Compute::ListableResourceCollection)

    @disk_params = [{
        "boot" => true,
        "diskType"=> "https://www.googleapis.com/compute/v1/projects/mock-project/zones/mock-zone/diskTypes/pd-standard",
        "type" => "PERSISTENT",
        "mode" => "READ_WRITE",
        "deviceName" => "",
        "source" => nil,
        "autoDelete" => "false"}]

    sizeGb = 10
    @disk_setup = {
      :sourceImage => stored_image.self_link,
      :zone => stored_zone.name,
      :name => stored_instance.name,
      :type => "https://www.googleapis.com/compute/v1/projects/mock-project/zones/mock-zone/diskTypes/pd-standard",
      :sizeGb => sizeGb }

    @result = {
      :name => stored_instance.name,
      :zone => stored_zone.name,
      :machineType => stored_machine_type.self_link,
      # :image => stored_image.self_link,
      :disks => @disk_params,
      :networkInterfaces => [{
        "network" => stored_network.self_link,
        "accessConfigs" => [{
          "name" => "External NAT",
          "type" => "ONE_TO_ONE_NAT"}]}],
      :serviceAccounts => [{
        "kind" => "compute#serviceAccount",
        "email" => "123845678986@project.gserviceaccount.com",
        "scopes" => [
          "https://www.googleapis.com/auth/userinfo.email",
          "https://www.googleapis.com/auth/compute",
          "https://www.googleapis.com/auth/devstorage.full_control"]}],
      :scheduling=>{
        "automaticRestart" => "false",
        "onHostMaintenance" => "TERMINATE"},
      :canIpForward=>false,
      :metadata => {"items" => []},
      :tags => {"items" => []}}
  end

  def setup(additional_disk=false)
    zones = double(Google::Compute::ListableResourceCollection)
    expect(zones).to receive(:get).with(stored_zone.name).and_return(stored_zone)

    machine_types = double(Google::Compute::ListableResourceCollection)
    expect(machine_types).to receive(:get).with({:name => stored_machine_type.name, :zone => stored_zone.name}).
    and_return(stored_machine_type)

    images = double(Google::Compute::ListableResourceCollection)
    expect(images).to receive(:get).with({:project => "mock-project", :name => stored_image.name}).
    and_return(stored_image)


    disks = double(Google::Compute::ListableResourceCollection)
    expect(disks).to receive(:insert).with(@disk_setup).and_return(stored_disk)

    networks = double(Google::Compute::ListableResourceCollection)
    expect(networks).to receive(:get).with(stored_network.name).and_return(stored_network)

    if additional_disk
      # Make sure we look for the disk
      expect(disks).to receive(:list).exactly(1).times.with({
        :zone => stored_zone.name,
        :name => "mock-disk"}).and_return([stored_disk])

      # We're goign to create a second disk
      @disk_params.push({
          "boot" => false,
          "type" => "PERSISTENT",
          "mode" => "READ_WRITE",
          "deviceName" => "mock-disk",
          "source" => "https://www.googleapis.com/compute/v1/projects/mock-project/zones/mock-zone/disks/mock-disk"})
    end

    expect(@instances).to receive(:get).with(:zone => stored_zone.name, :name => stored_instance.name).and_return(stored_instance)

    client = double(Google::Compute::Client, :instances => @instances,
      :images => images, :zones => zones,:machine_types => machine_types,
      :networks => networks, :disks => disks)
    allow(Google::Compute::Client).to receive(:from_json).and_return(client)
  end

  it "#run should invoke compute api to create an server with a service account" do
    setup
    @server_instance.config[:public_ip]='EPHEMERAL'
    allow(@server_instance.ui).to receive(:info)
    allow(@server_instance).to receive(:wait_for_disk)
    allow(@server_instance).to receive(:wait_for_sshd)
    expect(@server_instance).to receive(:bootstrap_for_node).with(stored_instance,'10.100.0.10').and_return(double("Chef::Knife::Bootstrap",:run => true))
    expect(@instances).to receive(:create).with(@result).and_return(stored_zone_operation)
    @server_instance.run
  end

  it "#run should create a server with secondary storage disk" do
    setup(true)
    @server_instance.config[:additional_disks] = 'mock-disk'
    @server_instance.config[:public_ip]='EPHEMERAL'
    allow(@server_instance.ui).to receive(:info)
    allow(@server_instance).to receive(:wait_for_disk)
    allow(@server_instance).to receive(:wait_for_sshd)
    expect(@server_instance).to receive(:bootstrap_for_node).with(stored_instance,'10.100.0.10').and_return(double("Chef::Knife::Bootstrap",:run => true))
    expect(@instances).to receive(:create).with(@result).and_return(stored_zone_operation)
    @server_instance.run
  end

  it "should read zone value from knife config file." do
    setup
    Chef::Config[:knife][:gce_zone] = stored_zone.name
    @server_instance.config[:public_ip]='EPHEMERAL'
    allow(@server_instance.ui).to receive(:info)
    allow(@server_instance).to receive(:wait_for_disk)
    allow(@server_instance).to receive(:wait_for_sshd)
    expect(@server_instance).to receive(:bootstrap_for_node).with(stored_instance,'10.100.0.10').and_return(double("Chef::Knife::Bootstrap",:run => true))
    expect(@instances).to receive(:create).with(@result).and_return(stored_zone_operation)
    @server_instance.run
  end

  it "create with public ip set to none" do
    setup
    @result = {
      :name => stored_instance.name,
      :zone => stored_zone.name,
      :machineType => stored_machine_type.self_link,
      # :image => stored_image.self_link,
      :disks => @disk_params,
      :networkInterfaces => [{"network" => stored_network.self_link}],
      :serviceAccounts => [{
        "kind" => "compute#serviceAccount",
        "email" => "123845678986@project.gserviceaccount.com",
        "scopes" => [
          "https://www.googleapis.com/auth/userinfo.email",
          "https://www.googleapis.com/auth/compute",
          "https://www.googleapis.com/auth/devstorage.full_control"]}],
      :scheduling=>{
        "automaticRestart" => "false",
        "onHostMaintenance" => "TERMINATE"},
      :canIpForward=>false,
      :metadata => {"items" => []},
      :tags => {"items" => []}}
    @server_instance.config[:public_ip]='NONE'
    allow(@server_instance.ui).to receive(:info)
    allow(@server_instance).to receive(:wait_for_disk)
    allow(@server_instance).to receive(:wait_for_sshd)
    expect(@server_instance).to receive(:bootstrap_for_node).with(stored_instance,'10.100.0.10').and_return(double("Chef::Knife::Bootstrap",:run => true))
    expect(@instances).to receive(:create).with(@result).and_return(stored_zone_operation)
    @server_instance.run
  end
end