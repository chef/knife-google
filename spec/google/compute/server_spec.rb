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

describe Google::Compute::Server do

  before(:each) do
    @mock_api_client=double(Google::APIClient, :authorization= => {}, :auto_refresh_token= => {})
    @mock_api_client.stub(:discovered_api).and_return(mock_compute)
    Google::APIClient.stub(:new).and_return(@mock_api_client)
  end

  let(:client) do
    Google::Compute::Client.from_json(mock_data_file(Google::Compute::Client))
  end

  it_should_behave_like Google::Compute::Resource

  it '#get should return an individual Server' do
    @mock_api_client.should_receive(:execute).
      with(:api_method => mock_compute.instances.get,
           :parameters => {:instance => 'mock-instance', :project => 'mock-project', :zone => 'mock-zone'}, :body_object => nil).
           and_return(mock_response(Google::Compute::Server))
    instance = client.instances.get(:name => 'mock-instance', :zone => 'mock-zone')
    instance.should be_a_kind_of Google::Compute::Server
    instance.name.should eq('mock-instance')
    instance.disks.should be_a_kind_of(Array)
    instance.network_interfaces.should be_a_kind_of(Array)
  end

  it '#list should return an array of Servers' do
    @mock_api_client.should_receive(:execute).
      with(:api_method => mock_compute.instances.list,
           :parameters => {:project => 'mock-project', :zone => 'mock-zone'}, :body_object => nil).
           and_return(mock_response(Google::Compute::Server, true))
    instances = client.instances.list(:zone => 'mock-zone')
    instances.should_not be_empty
    instances.all?{|i| i.is_a?(Google::Compute::Server)}.should be_true
  end

  it '#create should create an server' do
    project_url ='https://www.googleapis.com/compute/v1beta16/projects/mock-project'
    zone = project_url + '/zones/europe-west1-a'
    disk = project_url + zone + '/disks/mock-disk'
    machine_type = project_url + '/global/machineTypes/n1-highcpu-2'
    image = 'https://www.googleapis.com/compute/v1beta16/projects/debian-cloud/global/images/debian-7'
    network = project_url + '/global/networks/api-network'
    access_config = {'name' => 'External NAT', 'type' => 'ONE_TO_ONE_NAT'}

    @mock_api_client.should_receive(:execute).
      with(:api_method => mock_compute.instances.insert,
           :parameters => {:project => 'mock-project', :zone => 'mock-zone'},
           :body_object => {:name => 'mock-instance',
             :image => image,
             :zone => 'mock-zone',
             :disks => [disk],
             :machineType => machine_type,
             :metadata => {'items' => [{'key' => 'someKey', 'value' => 'someValue'}]},
             :networkInterfaces => [{'network' => network, 'accessConfigs' => [access_config]}]
           }).and_return(mock_response(Google::Compute::ZoneOperation))
    o = client.instances.create(:name => 'mock-instance',
                                :image => image,
                                :zone => 'mock-zone',
                                :disks => [disk],
                                :machineType => machine_type,
                                :metadata => {'items' => [{'key' => 'someKey', 'value' => 'someValue'}]},
                                :networkInterfaces => [{'network' => network, 'accessConfigs' => [access_config]}])
  end

  it '#delete should delete an server' do
    @mock_api_client.should_receive(:execute).
      with(:api_method => mock_compute.instances.delete,
           :parameters => {:project => 'mock-project', :instance => 'mock-instance', :zone => 'mock-zone'},
           :body_object => nil).
           and_return(mock_response(Google::Compute::ZoneOperation))
    o = client.instances.delete(:instance => 'mock-instance', :zone => 'mock-zone')
  end

  describe 'with a specific server' do

    before(:each) do
      Google::Compute::Resource.any_instance.stub(:update!)
    end

    let(:instance) do
      Google::Compute::Server.new(mock_hash(Google::Compute::Server).
                                  merge(:dispatcher => client.dispatcher))
    end

    it '#addAccessConfig should add access config to an existing server' do
    end

    it '#deleteAccessConfig should delete access config to an existing server' do
    end

    it '#serialPort should return serial port output of an existing server' do
      zone = 'https://www.googleapis.com/compute/v1beta16/projects/mock-project/zones/mock-zone'
      @mock_api_client.should_receive(:execute).
        with(:api_method => mock_compute.instances.get_serial_port_output,
             :parameters => {:project => 'mock-project', :instance => 'mock-instance', :zone => zone},
             :body_object => nil).
             and_return(mock_response(Google::Compute::SerialPortOutput))
      instance.serial_port_output.should be_a_kind_of(Google::Compute::SerialPortOutput)
      instance.serial_port_output.contents.should_not be_empty
    end
  end
end
