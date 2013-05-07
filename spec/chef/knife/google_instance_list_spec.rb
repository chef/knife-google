# Copyright 2013 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require 'spec_helper'

describe Chef::Knife::GoogleInstanceList do

  let(:knife_plugin) do
    Chef::Knife::GoogleInstanceList.new(["-Z"+stored_zone.name])
  end

  it "should enlist all the GCE instance when run invoked" do
    zones = mock(Google::Compute::ListableResourceCollection)
    zones.should_receive(:get).with(stored_zone.name).
      and_return(stored_zone)

    instances = mock(Google::Compute::DeletableResourceCollection)
    instances.should_receive(:list).with(:zone=>stored_zone.name).
      and_return([stored_instance])

    client = mock(Google::Compute::Client,
      :instances=>instances, :zones=>zones)
    Google::Compute::Client.stub!(:from_json).and_return(client)

    $stdout.should_receive(:write).with(kind_of(String))
    knife_plugin.run
  end
end
