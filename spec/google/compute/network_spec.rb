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

describe Google::Compute::Network do

  before(:each) do
    @mock_api_client=double(Google::APIClient, :authorization= =>{}, :auto_refresh_token= =>{})
    @mock_api_client.stub(:discovered_api).and_return(mock_compute)
    Google::APIClient.stub(:new).and_return(@mock_api_client)
  end

  let(:client) do
    Google::Compute::Client.from_json(mock_data_file(Google::Compute::Client))
  end

  it_should_behave_like Google::Compute::Resource
  
  it '#get should return an individual network' do
    @mock_api_client.should_receive(:execute).
      with(:api_method=>mock_compute.networks.get, 
           :parameters=>{'network'=>'mock-network', :project=>'mock-project'},:body_object=>nil).
           and_return(mock_response(Google::Compute::Network))
    network = client.networks.get('mock-network')
    network.should be_a_kind_of Google::Compute::Network
    network.name.should eq('mock-network')
    network.should respond_to(:ip_v4_range)
  end

  it '#list should return an array of networks' do
    @mock_api_client.should_receive(:execute).
      with(:api_method=>mock_compute.networks.list, 
           :parameters=>{ :project=>'mock-project'},:body_object=>nil).
           and_return(mock_response(Google::Compute::Network, true))
    networks = client.networks.list
    networks.should_not be_empty
    networks.all?{|n| n.is_a?(Google::Compute::Network)}.should be_true
  end

  it '#create should create a new network' do
    @mock_api_client.should_receive(:execute).
      with(:api_method=>mock_compute.networks.insert, 
           :parameters=>{ :project=>'mock-project'},
           :body_object=>{:name=>'mock-network', :IPv4Range=>'122.12.0.0/16'}).
           and_return(mock_response(Google::Compute::GlobalOperation))
    o = client.networks.create(:name=>'mock-network', :IPv4Range=>'122.12.0.0/16')
    o.should be_a_kind_of Google::Compute::GlobalOperation
  end

  it '#delete should delete an existing network' do
    @mock_api_client.should_receive(:execute).
      with(:api_method=>mock_compute.networks.delete, 
           :parameters=>{'network'=>'mock-network', :project=>'mock-project'},:body_object=>nil).
           and_return(mock_response(Google::Compute::GlobalOperation))
    client.networks.delete('mock-network')
  end
end
