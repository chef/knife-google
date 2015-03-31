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

describe Google::Compute::Image do

  before(:each) do
    @mock_api_client=double(Google::APIClient, :authorization= => {}, :auto_refresh_token= => {})
    @mock_api_client.stub(:discovered_api).and_return(mock_compute)
    Google::APIClient.stub(:new).and_return(@mock_api_client)
  end

  let(:client) do
    Google::Compute::Client.from_json(mock_data_file(Google::Compute::Client))
  end

  it_should_behave_like Google::Compute::Resource

  it '#get should return an individual image' do
    @mock_api_client.should_receive(:execute).
      with(:api_method => mock_compute.images.get,
           :parameters => {'image' => 'mock-image', :project => 'mock-project'}, :body_object => nil).
           and_return(mock_response(Google::Compute::Image))
    image = client.images.get('mock-image')
    image.should be_a_kind_of Google::Compute::Image
    image.name.should eq('mock-image')
    image.raw_disk.should have_key('source')
    image.raw_disk.should have_key('containerType')
  end

  it '#list should return an array of images' do
    @mock_api_client.should_receive(:execute).
      with(:api_method => mock_compute.images.list,
           :parameters => { :project => 'mock-project'}, :body_object => nil).
           and_return(mock_response(Google::Compute::Image, true))
    images = client.images.list
    images.should_not be_empty
    expect(images.all?{|i| i.is_a?(Google::Compute::Image)}).to be_truthy
  end
  it '#create should create a new image' do
    storage = 'https://www.googleapis.com/storage/projects/mock-project/bucket/object'
    @mock_api_client.should_receive(:execute).
      with(:api_method => mock_compute.images.insert,
           :parameters => { :project => 'mock-project'},
           :body_object => {:name => 'mock-image',
              :rawDisk => {'containerType' => 'TAR', 'source' => storage},
              :sourceType => 'RAW'}).
           and_return(mock_response(Google::Compute::GlobalOperation))
    o = client.images.create(:name => 'mock-image',
              :rawDisk => {'containerType' => 'TAR', 'source' => storage},
              :sourceType => 'RAW')

    o.should be_a_kind_of Google::Compute::GlobalOperation
  end

  it '#delete should delete an existing image' do
    @mock_api_client.should_receive(:execute).
      with(:api_method => mock_compute.images.delete,
           :parameters => { :project => 'mock-project', 'image' => 'mock-image'}, :body_object => nil).
           and_return(mock_response(Google::Compute::GlobalOperation))
    o = client.images.delete('mock-image')
    o.should be_a_kind_of Google::Compute::GlobalOperation
  end
end
