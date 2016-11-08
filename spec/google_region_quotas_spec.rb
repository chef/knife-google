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
require "chef/knife/google_region_quotas"
require "support/shared_examples_for_command"

describe Chef::Knife::Cloud::GoogleRegionQuotas do
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

  describe "#execute_command" do
    let(:ui)      { double("ui") }
    let(:regions) { [region1] }

    before do
      allow(command).to receive(:ui).and_return(ui)
      allow(ui).to receive(:msg)
      allow(ui).to receive(:color)
      allow(ui).to receive(:list)
      expect(service).to receive(:list_regions).and_return(regions)
    end

    context "when the quota information for the region is nil" do
      let(:region1) { double("region1", name: "my-region", quotas: nil) }

      it "prints a warning and does not output a list" do
        expect(ui).to receive(:warn).with("No quota information available for this region.")
        expect(ui).not_to receive(:list)
        command.execute_command
      end
    end

    context "when the quota information for the region is empty" do
      let(:region1) { double("region1", name: "my-region", quotas: []) }

      it "prints a warning and does not output a list" do
        expect(ui).to receive(:warn).with("No quota information available for this region.")
        expect(ui).not_to receive(:list)
        command.execute_command
      end
    end

    context "when there is quota information available" do
      let(:quota1) { double("quota1", metric: "metric1", limit: "limit1", usage: "usage1") }
      let(:quota2) { double("quota2", metric: "metric2", limit: "limit2", usage: "usage2") }
      let(:region1) { double("region1", name: "my-region", quotas: [quota1, quota2]) }

      it "formats the output and outputs a list" do
        expect(command).to receive(:format_name).with("metric1")
        expect(command).to receive(:format_name).with("metric2")
        expect(command).to receive(:format_number).with("limit1")
        expect(command).to receive(:format_number).with("limit2")
        expect(command).to receive(:format_number).with("usage1")
        expect(command).to receive(:format_number).with("usage2")
        expect(ui).to receive(:list).and_return("list_output")
        expect(ui).to receive(:msg).with("list_output")

        command.execute_command
      end
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
