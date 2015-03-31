# Copyright 2013 Google Inc. All Rights Reserved.
#
# Copyright 2013 Google Inc.
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

describe Google::Compute::MachineType do

  before(:each) do
    @mock_api_client=double(Google::APIClient, :authorization= => {}, :auto_refresh_token= => {})
    @mock_api_client.stub(:discovered_api).and_return(mock_compute)
    Google::APIClient.stub(:new).and_return(@mock_api_client)
  end

  let(:client) do
    Google::Compute::Client.from_json(mock_data_file(Google::Compute::Client))
  end

  it_should_behave_like Google::Compute::Resource

  it '#get should return an individual machine types' do

    @mock_api_client.should_receive(:execute).
      with(:api_method => mock_compute.machine_types.get,
           :parameters => {'machineType' => 'mock-machine-type', :project => 'mock-project'}, :body_object => nil).
           and_return(mock_response(Google::Compute::MachineType))

    machine_type = client.machine_types.get('mock-machine-type')
    machine_type.should be_a_kind_of Google::Compute::MachineType
    machine_type.name.should eq('mock-machine-type')
    machine_type.guest_cpus.should be_a_kind_of(Fixnum)
  end
  it '#list should return an array of machine types' do
  @mock_api_client.should_receive(:execute).
    with(:api_method => mock_compute.machine_types.list,
         :parameters => { :project => 'mock-project'}, :body_object => nil).
         and_return(mock_response(Google::Compute::MachineType, true))
    mts = client.machine_types.list
    mts.should_not be_empty
    expect(mts.all?{|mt| mt.is_a?(Google::Compute::MachineType)}).to be_truthy
  end
end
