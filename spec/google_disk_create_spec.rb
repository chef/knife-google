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
require "chef/knife/google_disk_create"
require "support/shared_examples_for_command"

describe Chef::Knife::Cloud::GoogleDiskCreate do
  let(:command) { described_class.new(%w{disk1}) }
  let(:service) { double("service") }

  before do
    allow(command).to receive(:service).and_return(service)
  end

  it_behaves_like Chef::Knife::Cloud::Command, described_class.new

  describe "#validate_params!" do
    before do
      allow(command).to receive(:check_for_missing_config_values!)
      allow(command).to receive(:valid_disk_size?).and_return(true)
    end

    it "checks for missing config values" do
      expect(command).to receive(:check_for_missing_config_values!).with(:disk_size, :disk_type)

      command.validate_params!
    end

    it "does not raise an exception if all params are good" do
      expect { command.validate_params! }.not_to raise_error
    end

    it "raises an exception if the disk size is invalid" do
      expect(command).to receive(:valid_disk_size?).and_return(false)
      expect { command.validate_params! }.to raise_error(RuntimeError, "Disk size must be between 10 and 10,000")
    end

    context "when no disk name is provided" do
      let(:command) { described_class.new }
      it "raises an exception" do
        expect { command.validate_params! }.to raise_error(RuntimeError, "Please specify a disk name.")
      end
    end
  end

  describe "#execute_command" do
    it "calls the service to create the disk" do
      expect(command).to receive(:locate_config_value).with(:disk_size).and_return("size")
      expect(command).to receive(:locate_config_value).with(:disk_type).and_return("type")
      expect(command).to receive(:locate_config_value).with(:disk_source).and_return("source")
      expect(service).to receive(:create_disk).with("disk1", "size", "type", "source")

      command.execute_command
    end
  end
end
