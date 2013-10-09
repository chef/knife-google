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
require 'spec_helper'

describe Google::Compute::Disk do

  before(:each) do
    @mock_api_client=double(Google::APIClient, :authorization= =>{}, :auto_refresh_token= =>{})
    @mock_api_client.stub(:discovered_api).and_return(mock_compute)
    Google::APIClient.stub(:new).and_return(@mock_api_client)
  end

  let(:client) do
    Google::Compute::Client.from_json(mock_data_file(Google::Compute::Client))
  end

  it_should_behave_like Google::Compute::Resource

  it "#get should return an individual disk by name" do
    @mock_api_client.should_receive(:execute).
      with(:api_method=>mock_compute.disks.get, 
           :parameters=>{"disk"=>"mock-disk", :project=>"mock-project", :zone=>"mock-zone"},:body_object=>nil).
           and_return(mock_response(Google::Compute::Disk))
    disk = client.disks.get(:name=>"mock-disk", :zone=>"mock-zone")
    disk.should be_a_kind_of Google::Compute::Disk
    disk.name.should eq("mock-disk")
  end

#  TODO(erjohnso): come back to this and see about fixing it
#  it "#get return an individual disk by passing the disk object also" do
#    @mock_api_client.should_receive(:execute).
#      with(:api_method=>mock_compute.disks.get, 
#           :parameters=>{"disk"=>"mock-disk", :project=>"mock-project", :zone=>"mock-zone"},:body_object=>nil).
#           and_return(mock_response(Google::Compute::Disk))
#
#    disk = client.disks.get(:disk=>instance_from_mock_data(Google::Compute::Disk), :zone=>instance_from_mock_data(Google::Compute::Zone))
#    disk.should be_a_kind_of Google::Compute::Disk
#    disk.name.should eq('mock-disk')
#  end

  it "#get should return an individual disk by passing a hash with name key also" do
    @mock_api_client.should_receive(:execute).
      with(:api_method=>mock_compute.disks.get, 
           :parameters=>{"disk"=>"mock-disk", :project=>"mock-project", :zone=>"mock-zone"},:body_object=>nil).
           and_return(mock_response(Google::Compute::Disk))

    disk = client.disks.get(:name=>'mock-disk', :zone=>"mock-zone")
    disk.should be_a_kind_of Google::Compute::Disk
    disk.name.should eq('mock-disk')
  end

  it "#list should return an array of disks" do
    @mock_api_client.should_receive(:execute).
      with(:api_method=>mock_compute.disks.list, 
           :parameters=>{ :project=>"mock-project", :zone=>"mock-zone"},:body_object=>nil).
           and_return(mock_response(Google::Compute::Disk, true))
    disks = client.disks.list(:zone=>"mock-zone")
    disks.all?{|disk| disk.is_a?(Google::Compute::Disk)}.should be_true
  end

  it "#create should create a new disk" do
    #zone = 'https://www.googleapis.com/compute/v1beta16/projects/mock-project/zones/mock-zone'
    zone = 'mock-zone'
    @mock_api_client.should_receive(:execute).
      with(:api_method=>mock_compute.disks.insert, 
           :parameters=>{ :project=>"mock-project", :zone=>"mock-zone"},
           :body_object=>{:name=>"xxx", :sizeGb=>2, :zone=>"mock-zone"}).
           and_return(mock_response(Google::Compute::ZoneOperation))
    o = client.disks.create(:name=>'xxx', :sizeGb=>2, :zone=>zone)
    o.should be_a_kind_of Google::Compute::ZoneOperation
  end

  it "#insert should create a new disk also" do
    #zone = 'https://www.googleapis.com/compute/v1beta16/projects/mock-project/zones/mock-zone'
    zone = 'mock-zone'
    @mock_api_client.should_receive(:execute).
      with(:api_method=>mock_compute.disks.insert, 
           :parameters=>{ :project=>"mock-project", :zone=>"mock-zone"},
           :body_object=>{:name=>"xxx", :sizeGb=>2, :zone=>"mock-zone"}).
           and_return(mock_response(Google::Compute::ZoneOperation))
    o = client.disks.insert(:name=>'xxx', :sizeGb=>2, :zone=>zone)
    o.should be_a_kind_of Google::Compute::ZoneOperation
  end

  it "#delete should delete an existing disk" do
    @mock_api_client.should_receive(:execute).
      with(:api_method=>mock_compute.disks.delete, 
           :parameters=>{ :project=>"mock-project","disk"=>"mock-disk", :zone=>"mock-zone"},:body_object =>nil).
           and_return(mock_response(Google::Compute::ZoneOperation))
    o = client.disks.delete("disk"=>"mock-disk", :zone=>"mock-zone")
    o.should be_a_kind_of Google::Compute::ZoneOperation
  end

  it "#createSnapshot should create a new snapshot" do
    zone = 'mock-zone'
    disk = 'https://www.googleapis.com/compute/v1beta16/projects/mock-project/disks/mock-disk'
    @mock_api_client.should_receive(:execute).
      with(:api_method=>mock_compute.disks.create_snapshot,
           :parameters=>{:project=>"mock-project", :zone=>zone, :disk=>disk}, :body_object=>nil).
           and_return(mock_response(Google::Compute::ZoneOperation))
    o = client.disks.create_snapshot(:project=>"mock-project", :zone=>zone, :disk=>disk)
    o.should be_a_kind_of Google::Compute::ZoneOperation
  end
end
