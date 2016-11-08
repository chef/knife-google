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
require "chef/knife/google_disk_delete"
require "support/shared_examples_for_command"

describe Chef::Knife::Cloud::GoogleDiskDelete do
  let(:command) { described_class.new(%w{disk1 disk2}) }
  let(:service) { double("service") }

  before do
    allow(command).to receive(:service).and_return(service)
  end

  it_behaves_like Chef::Knife::Cloud::Command, described_class.new

  describe "#validate_params!" do
    before do
      allow(command).to receive(:check_for_missing_config_values!)
    end

    it "checks for missing config values" do
      expect(command).to receive(:check_for_missing_config_values!)

      command.validate_params!
    end

    it "does not raise an exception if all params are good" do
      expect { command.validate_params! }.not_to raise_error
    end

    context "when no disk name is provided" do
      let(:command) { described_class.new }
      it "raises an exception" do
        expect { command.validate_params! }.to raise_error(RuntimeError, "You must specify at least one disk to delete.")
      end
    end
  end

  describe "#execute_command" do
    it "calls the service to delete each disk" do
      expect(service).to receive(:delete_disk).with("disk1")
      expect(service).to receive(:delete_disk).with("disk2")

      command.execute_command
    end
  end
end
