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
require "chef/knife/google_server_list"
require "support/shared_examples_for_command"

describe Chef::Knife::Cloud::GoogleServerList do
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

  describe "#format_status_value" do
    it "returns green when the status is ready" do
      expect(command.ui).to receive(:color).with("ready", :green)
      command.format_status_value("ready")
    end

    it "returns red when the status is stopped" do
      expect(command.ui).to receive(:color).with("stopped", :red)
      command.format_status_value("stopped")
    end

    it "returns red when the status is stopping" do
      expect(command.ui).to receive(:color).with("stopping", :red)
      command.format_status_value("stopping")
    end

    it "returns red when the status is terminated" do
      expect(command.ui).to receive(:color).with("terminated", :red)
      command.format_status_value("terminated")
    end

    it "returns yellow when the status is requested" do
      expect(command.ui).to receive(:color).with("requested", :yellow)
      command.format_status_value("requested")
    end

    it "returns yellow when the status is provisioning" do
      expect(command.ui).to receive(:color).with("provisioning", :yellow)
      command.format_status_value("provisioning")
    end

    it "returns yellow when the status is staging" do
      expect(command.ui).to receive(:color).with("staging", :yellow)
      command.format_status_value("staging")
    end
  end
end
