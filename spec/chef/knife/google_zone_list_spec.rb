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

describe Chef::Knife::GoogleZoneList do
  let(:knife_plugin) do
    Chef::Knife::GoogleZoneList.new([])
  end

  it "should enlist all the GCE zones when run invoked" do
    client = double(Google::Compute::Client)
    Google::Compute::Client.stub(:from_json).
      and_return(client)
    client.should_receive(:zones).
      and_return(double("zone-collection", :list => [stored_zone]))
    expect(knife_plugin.ui).to receive(:info)
    knife_plugin.run
  end
end
