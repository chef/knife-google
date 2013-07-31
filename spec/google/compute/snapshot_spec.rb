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

describe Google::Compute::Snapshot do

  before(:each) do
    @mock_api_client=mock(Google::APIClient, :authorization= =>{}, :auto_refresh_token= =>{})
    @mock_api_client.stub!(:discovered_api).and_return(mock_compute)
    Google::APIClient.stub!(:new).and_return(@mock_api_client)
  end

  let(:client) do
    Google::Compute::Client.from_json(mock_data_file(Google::Compute::Client))
  end

  it_should_behave_like Google::Compute::Resource

  it "#get should return an individual snapshot" do
    @mock_api_client.should_receive(:execute).
      with(:api_method=>mock_compute.snapshots.get, 
           :parameters=>{"snapshot"=>"mock-snapshot", :project=>"mock-project"},:body_object=>nil).
           and_return(mock_response(Google::Compute::Snapshot))
    snapshot = client.snapshots.get('mock-snapshot')
    snapshot.should be_a_kind_of Google::Compute::Snapshot
    snapshot.name.should eq('mock-snapshot')
  end

  it "#list should return an array of snapshots" do
    @mock_api_client.should_receive(:execute).
      with(:api_method=>mock_compute.snapshots.list, 
           :parameters=>{:project=>"mock-project"},:body_object=>nil).
           and_return(mock_response(Google::Compute::Snapshot,true))
    snapshots = client.snapshots.list
    snapshots.should_not be_empty
    snapshots.all?{|s| s.is_a?(Google::Compute::Snapshot)}.should be_true
  end

  it "#create should create a new snapshot" do
    disk = 'https://www.googleapis.com/compute/v1beta15/projects/mock-project/disks/mock-disk'
    @mock_api_client.should_receive(:execute).
      with(:api_method=>mock_compute.snapshots.insert, 
           :parameters=>{:project=>"mock-project"},
           :body_object=>{:name=>'api-snapshot', :sourceDisk=>disk}).
           and_return(mock_response(Google::Compute::GlobalOperation))

    o = client.snapshots.create(:name=>'api-snapshot', :sourceDisk=>disk)
    o.should be_a_kind_of Google::Compute::GlobalOperation
  end

  it "#delete should delete an existing snapshot" do
    @mock_api_client.should_receive(:execute).
      with(:api_method=>mock_compute.snapshots.delete, 
           :parameters=>{:project=>"mock-project",'snapshot'=>'mock-snapshot'},:body_object=>nil).
           and_return(mock_response(Google::Compute::GlobalOperation))
    o =  client.snapshots.delete('mock-snapshot')
  end
end
