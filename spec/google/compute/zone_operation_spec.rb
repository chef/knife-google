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

describe Google::Compute::ZoneOperation do

  before(:each) do
    @mock_api_client=double(Google::APIClient, :authorization= => {}, :auto_refresh_token= => {})
    @mock_api_client.stub(:discovered_api).and_return(mock_compute)
    Google::APIClient.stub(:new).and_return(@mock_api_client)
  end

  let(:client) do
    Google::Compute::Client.from_json(mock_data_file(Google::Compute::Client))
  end

  it_should_behave_like Google::Compute::Resource

  it '#list should return an array of zone operations' do
    @mock_api_client.should_receive(:execute).
      with(:api_method => mock_compute.zone_operations.list,
           :parameters => { :project => 'mock-project'}, :body_object => nil).
           and_return(mock_response(Google::Compute::ZoneOperation, true))

    operations = client.zoneOperations.list
    operations.should_not be_empty
    expect(operations.all?{|o| o.is_a?(Google::Compute::ZoneOperation)}).to be_truthy
  end

  it '#get should return an individual zone operation' do
    @mock_api_client.should_receive(:execute).
      with(:api_method => mock_compute.zone_operations.get,
           :parameters => {'zoneOperation' => 'mock-zone-operation', :project => 'mock-project'}, :body_object => nil).
           and_return(mock_response(Google::Compute::ZoneOperation))

    operation = client.zoneOperations.get('mock-zone-operation')
    operation.should be_a_kind_of Google::Compute::ZoneOperation
    operation.name.should eq('mock-zone-operation')
    operation.should respond_to(:progress)
    operation.start_time.should be_a_kind_of(Time)
  end

  it '#delete should delete an existing zone operation' do
    @mock_api_client.should_receive(:execute).
      with(:api_method => mock_compute.zone_operations.delete,
           :parameters => {'zoneOperation' => 'mock-zone-operation', :project => 'mock-project'}, :body_object => nil).
           and_return(mock_response)

    client.zoneOperations.delete('mock-zone-operation')
  end
end
