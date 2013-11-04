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

describe Google::Compute::Project do

  before(:each) do
    @mock_api_client=double(Google::APIClient, :authorization= => {}, :auto_refresh_token= => {})
    @mock_api_client.stub(:discovered_api).and_return(mock_compute)
    Google::APIClient.stub(:new).and_return(@mock_api_client)
  end

  let(:client) do
    Google::Compute::Client.from_json(mock_data_file(Google::Compute::Client))
  end

  it_should_behave_like Google::Compute::Resource

  it '#get should return an individual project' do
    @mock_api_client.should_receive(:execute).
      with(:api_method => mock_compute.projects.get,
           :parameters => {:project => 'mock-project', 'project' => 'mock-project'}, :body_object => nil).
           and_return(mock_response(Google::Compute::Project))
    project = client.projects.get('mock-project')
    project.should be_a_kind_of Google::Compute::Project
  end

  describe '#setCommonInstanceMetadata'

    before(:each) do
      Google::Compute::Resource.any_instance.stub(:update!)
    end

    let(:project) do
      Google::Compute::Project.new(mock_hash(Google::Compute::Project).
                                   merge(:dispatcher => client.dispatcher))
    end

    it 'should be able to add common instance metadata' do
      @mock_api_client.should_receive(:execute).
        with(:api_method => mock_compute.projects.set_common_instance_metadata,
             :parameters => {:project => 'mock-project'},
             :body_object => {'kind' => 'compute#metadata',
             'items' => [{'key' => 'mock-key', 'value' => 'mock-value'},
               {'key' => 'testKey', 'value' => 'testValue'}]}).
               and_return(mock_response)
      project.add_common_instance_metadata!('testKey' => 'testValue')
    end

    it 'should be able to remove common instance metadata' do
      @mock_api_client.should_receive(:execute).
        with(:api_method => mock_compute.projects.set_common_instance_metadata,
             :parameters => {:project => 'mock-project'},
             :body_object => {'kind' => 'compute#metadata',
             'items' => []}).
               and_return(mock_response)
      project.remove_common_instance_metadata!('mock-key' => 'mock-value')
    end
end

