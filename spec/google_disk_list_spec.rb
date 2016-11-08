# frozen_string_literal: true
#
# Author:: Chef Partner Engineering (<partnereng@chef.io>)
# Copyright:: Copyright (c) 2016 Chef Software, Inc.
# License:: Apache License, Version 2.0
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

require "spec_helper"
require "chef/knife/google_disk_list"
require "support/shared_examples_for_command"

describe Chef::Knife::Cloud::GoogleDiskList do
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
  end

  describe "#query_resource" do
    it "uses the service to list disks" do
      expect(service).to receive(:list_disks).and_return("disks")
      expect(command.query_resource).to eq("disks")
    end
  end

  describe "#format_status_value" do
    it "returns green when the status is ready" do
      expect(command.ui).to receive(:color).with("ready", :green)
      command.format_status_value("ready")
    end

    it "returns red when the status is stopped" do
      expect(command.ui).to receive(:color).with("stopped", :red)
      command.format_status_value("stopped")
    end
  end

  describe "#format_disk_type" do
    it "returns a properly-formatted disk type" do
      expect(command.format_disk_type("a/b/c/disk_type")).to eq("disk_type")
    end
  end

  describe "#format_source_image" do
    it "returns 'unknown' if the source is nil" do
      expect(command.format_source_image(nil)).to eq("unknown")
    end

    it "returns 'unknown' if the source is empty" do
      expect(command.format_source_image([])).to eq("unknown")
    end

    it "returns a properly-formatted image URL" do
      expect(command.format_source_image("/1/2/3/4/5/6/image_name")).to eq("4/5/6/image_name")
    end
  end

  describe "#format_users" do
    it "returns 'unknown' if the source is nil" do
      expect(command.format_users(nil)).to eq("none")
    end

    it "returns 'unknown' if the source is empty" do
      expect(command.format_users([])).to eq("none")
    end

    it "returns a properly-formatted user URL" do
      expect(command.format_users(["/1/2/3/4/5/6/user1", "/1/2/3/4/5/6/user2"])).to eq("3/4/5/6/user1, 3/4/5/6/user2")
    end
  end
end
