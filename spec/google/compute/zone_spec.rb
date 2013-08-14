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

describe Google::Compute::Zone do

  before(:each) do
    @mock_api_client=double(Google::APIClient, :authorization= =>{}, :auto_refresh_token= =>{})
    @mock_api_client.stub(:discovered_api).and_return(mock_compute)
    Google::APIClient.stub(:new).and_return(@mock_api_client)
  end

  let(:client) do
    Google::Compute::Client.from_json(mock_data_file(Google::Compute::Client))
  end

  it_should_behave_like Google::Compute::Resource

  it '#get should return an individual zone' do
    @mock_api_client.should_receive(:execute).
      with(:api_method=>mock_compute.zones.get, 
           :parameters=>{'zone'=>'mock-zone', :project=>'mock-project'},:body_object=>nil).
           and_return(mock_response(Google::Compute::Zone))
    zone = client.zones.get('mock-zone')
    zone.should be_a_kind_of Google::Compute::Zone
    zone.name.should eq('mock-zone')
  end

  it '#list should return an array of zones' do
    @mock_api_client.should_receive(:execute).
      with(:api_method=>mock_compute.zones.list, 
           :parameters=>{ :project=>'mock-project'},:body_object=>nil).
           and_return(mock_response(Google::Compute::Zone, true))
    zones = client.zones.list
    zones.should_not be_empty
    zones.all?{|zone| zone.is_a?(Google::Compute::Zone)}.should be_true
  end

end
