#
# Author:: Kapil Chouhan (<kapil.chouhan@msystechnologies.com>)
# Copyright:: Copyright (c) 2018-2019 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "spec_helper"
require "chef/knife/google_image_list"
require "support/shared_examples_for_command"

class Tester
  include Chef::Knife::Cloud::GoogleServiceHelpers
end

describe Chef::Knife::Cloud::GoogleImageList do
  let(:tester) { Tester.new }
  let(:command) { described_class.new }
  let(:service) { double("service") }

  before do
    allow(command).to receive(:service).and_return(service)
  end

  it_behaves_like Chef::Knife::Cloud::Command, described_class.new

  describe "#validate_params!" do
    it "checks for missing config values" do
      expect(command).to receive(:check_for_missing_config_values!)

      command.validate_params!
    end

    it "raises an exception if the gce_project is missing" do
      ui = double("ui")
      expect(tester).to receive(:ui).and_return(ui)
      expect(tester).to receive(:locate_config_value).with(:gce_project).and_return(nil)
      expect(ui).to receive(:error).with("The following required parameters are missing: gce_project")
      expect { tester.check_for_missing_config_values! }.to raise_error(RuntimeError)
    end
  end

  describe "#query_resource" do
    it "uses the service to list images" do
      expect(service).to receive(:list_images).and_return("images")
      expect(command.query_resource).to eq("images")
    end
  end

  describe "#find_project_name" do
    let(:self_link) { "https://www.googleapis.com/compute/v1/projects/centos-cloud/global/images/centos-6-v20190916" }

    it "returns project name" do
      expect(command.find_project_name(self_link)).to eq("centos-cloud")
    end
  end

  describe "#format_disk_size_value" do
    let(:disk_size) { 32 }

    it "returns project name" do
      expect(command.format_disk_size_value(disk_size)).to eq("32 GB")
    end
  end
end
