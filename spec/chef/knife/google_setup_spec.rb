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

describe Chef::Knife::GoogleSetup do
  let(:knife_plugin) { Chef::Knife::GoogleSetup.new(["-f credential.json"]) }
  it "should invoke the google-compute-client-ruby setup process" do
    Google::Compute::Client.should_receive(:setup)
    knife_plugin.run
  end
end
