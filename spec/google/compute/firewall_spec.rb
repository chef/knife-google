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
#
require 'spec_helper'

describe Google::Compute::Firewall do

  before(:each) do
    @mock_api_client=mock(Google::APIClient, :authorization= =>{}, :auto_refresh_token= =>{})
    @mock_api_client.stub!(:discovered_api).and_return(mock_compute)
    Google::APIClient.stub!(:new).and_return(@mock_api_client)
  end

  let(:client) do
    Google::Compute::Client.from_json(mock_data_file(Google::Compute::Client))
  end

  it_should_behave_like Google::Compute::Resource
  
  it "#get should return an individual firewall" do
    @mock_api_client.should_receive(:execute).
      with(:api_method=>mock_compute.firewalls.get, 
           :parameters=>{"firewall"=>"mock-firewall", :project=>"mock-project"},:body_object=>nil).
           and_return(mock_response(Google::Compute::Firewall))
    fw = client.firewalls.get('mock-firewall')
    fw.should be_a_kind_of Google::Compute::Firewall
    fw.name.should eq('mock-firewall')
  end

  it "#list should return an array of firewalls" do
    @mock_api_client.should_receive(:execute).
      with(:api_method=>mock_compute.firewalls.list, 
           :parameters=>{:project=>"mock-project"},:body_object=>nil).
           and_return(mock_response(Google::Compute::Firewall,true))
    fws = client.firewalls.list
    fws.should_not be_empty
    fws.all?{|f| f.is_a?(Google::Compute::Firewall)}.should be_true
  end

  it "#create should create a new firewall" do
    network = 'https://www.googleapis.com/compute/v1beta15/projects/mock-project/networks/mock-network'
    ingress= {'IPProtocol'=>'tcp',"ports"=>["80"]}
    @mock_api_client.should_receive(:execute).
      with(:api_method=>mock_compute.firewalls.insert, 
           :parameters=>{:project=>"mock-project"},
           :body_object=>{:name =>'mock-firewall',
              :network=>network,
              :sourceRanges=>['10.12.0.0/24'],
              :allowed=>[ingress]}).
           and_return(mock_response(Google::Compute::GlobalOperation))

    o = client.firewalls.create(:name=>'mock-firewall',
                                :network=>network,
                                :sourceRanges=>['10.12.0.0/24'],
                                :allowed=>[ingress]
                                )
    o.should be_a_kind_of Google::Compute::GlobalOperation
  end

  it "#delete should delete an existing firewall" do
    @mock_api_client.should_receive(:execute).
      with(:api_method=>mock_compute.firewalls.delete, 
           :parameters=>{:project=>"mock-project",'firewall'=>'mock-firewall'},:body_object=>nil).
           and_return(mock_response(Google::Compute::GlobalOperation))
    o = client.firewalls.delete('mock-firewall')
  end

  describe "#patch" do

    before(:each) do
      Google::Compute::Resource.any_instance.stub(:update!)
    end

    let(:firewall) do
      Google::Compute::Firewall.new(mock_hash(Google::Compute::Firewall).
                                    merge(:dispatcher=>client.dispatcher))
    end

    it "#source_tags= should update the source tags" do
      @mock_api_client.should_receive(:execute).
        with(:api_method=>mock_compute.firewalls.patch, 
           :parameters=>{:project=>"mock-project",:firewall=>'mock-firewall'},
           :body_object=>{:sourceTags=>["all"], :name=>"mock-firewall", :network=>firewall.network}).
           and_return(mock_response(Google::Compute::GlobalOperation))

      firewall.source_tags= ["all"]
    end

    it "#target_tags= should update the target tags" do
      @mock_api_client.should_receive(:execute).
        with(:api_method=>mock_compute.firewalls.patch, 
           :parameters=>{:project=>"mock-project",:firewall=>'mock-firewall'},
           :body_object=>{:targetTags=>["all"], :name=>"mock-firewall", :network=>firewall.network}).
           and_return(mock_response(Google::Compute::GlobalOperation))
      firewall.target_tags= ["all"]
    end

    it "#source_ranges= should update the source ranges" do
      @mock_api_client.should_receive(:execute).
        with(:api_method=>mock_compute.firewalls.patch, 
           :parameters=>{:project=>"mock-project",:firewall=>'mock-firewall'},
           :body_object=>{:sourceRanges=>["10.10.12.0/24"], :name=>"mock-firewall", :network=>firewall.network}).
           and_return(mock_response(Google::Compute::GlobalOperation))
      firewall.source_ranges= ["10.10.12.0/24"]
    end

    it "#allowed= should update the source allowed traffic" do
      ingress= {'IPProtocol'=>'udp',"ports"=>["53"]}
      @mock_api_client.should_receive(:execute).
        with(:api_method=>mock_compute.firewalls.patch, 
           :parameters=>{:project=>"mock-project",:firewall=>'mock-firewall'},
           :body_object=>{:allowed=>[ingress], :name=>"mock-firewall", :network=>firewall.network}).
           and_return(mock_response(Google::Compute::GlobalOperation))
      firewall.allowed= [ingress]
    end
  end
end
