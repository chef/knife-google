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

describe Chef::Knife::GoogleBase do
  let(:knife_plugin) { Chef::Knife::GoogleServerList.new(["-Z"+stored_zone.name]) }

  it "#client should return a Google::Compute::Client" do
    Google::Compute::Client.should_receive(:from_json).
      and_return(mock(Google::Compute::Client))
    knife_plugin.client
  end

  it "#selflink2name should return name from a seleflink url" do
    knife_plugin.selflink2name(
      'https://www.googleapis.com/compute/v1beta15/projects/mock-project/category/resource').
      should eq('resource')
  end

  it "#msg_pair should invoke ui.info with labe : value string" do
    knife_plugin.ui.should_receive(:info).
      with("#{knife_plugin.ui.color("label", :cyan)}: value")
    knife_plugin.msg_pair("label","value")
  end

  it "#private_ips should extract private ip as an array from a GCE server" do
    knife_plugin.private_ips(stored_instance).should eq(['10.100.0.10'])
  end

  it "#public_ips should extract private ip as an array from a GCE server" do
    knife_plugin.public_ips(stored_instance).should eq(['11.1.1.11'])
  end
end
