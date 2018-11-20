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
require "chef/knife/google_project_quotas"
require "support/shared_examples_for_command"

class Tester
  include Chef::Knife::Cloud::GoogleServiceHelpers
end

describe Chef::Knife::Cloud::GoogleProjectQuotas do
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
    it "uses the service to list project quotas" do
      expect(service).to receive(:list_project_quotas).and_return("quotas")
      expect(command.query_resource).to eq("quotas")
    end
  end

  describe "#format_name" do
    it "returns a properly-formatted name" do
      expect(command.format_name("something_cool_here")).to eq("Something Cool Here")
    end
  end

  describe "#format_number" do
    it "returns an integer as a string if the number is a whole number" do
      expect(command.format_number(2.0)).to eq("2")
    end

    it "returns the number as-is if it is not a whole number" do
      expect(command.format_number(2.5)).to eq("2.5")
    end
  end
end
