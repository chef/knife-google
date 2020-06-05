# frozen_string_literal: true
#
# Author:: Chef Partner Engineering (<partnereng@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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
require "chef/knife/cloud/google_service"
require "chef/knife/cloud/google_service_helpers"

describe Chef::Knife::Cloud::GoogleServiceHelpers do
  let(:tester) { Tester.new }

  describe "#create_service_instance" do
    it "creates a GoogleService instance" do
      tester.config[:gce_project] = "test_project"
      tester.config[:gce_zone] = "test_zone"
      tester.config[:request_timeout] = 123
      tester.config[:request_refresh_rate] = 321
      tester.config[:gce_max_pages] = 456
      tester.config[:gce_max_page_size] = 654

      expect(Chef::Knife::Cloud::GoogleService).to receive(:new).with(
        project:       "test_project",
        zone:          "test_zone",
        wait_time:     123,
        refresh_rate:  321,
        max_pages:     456,
        max_page_size: 654
      ).and_return("service_object")

      expect(tester.create_service_instance).to eq("service_object")
    end
  end

  describe "#check_for_missing_config_values" do
    it "does not raise an exception if all parameters are present" do
      tester.config[:gce_project] = "project"
      tester.config[:key1] = "value1"
      tester.config[:key2] = "value2"

      expect { tester.check_for_missing_config_values!(:key1, :key2) }.not_to raise_error
    end

    it "raises an exception if a parameter is missing" do
      ui = double("ui")
      expect(tester).to receive(:ui).and_return(ui)
      tester.config[:gce_project] = "project"
      tester.config[:key1] = "value1"
      expect(ui).to receive(:error).with("The following required parameters are missing: key2")
      expect { tester.check_for_missing_config_values!(:key1, :key2) }.to raise_error(RuntimeError)
    end
  end

  describe "#private_ip_for" do
    it "returns the IP address if it exists" do
      network_interface = double("network_interface", network_ip: "1.2.3.4")
      server            = double("server", network_interfaces: [network_interface])

      expect(tester.private_ip_for(server)).to eq("1.2.3.4")
    end

    it "returns 'unknown' if the IP cannot be found" do
      server = double("server")

      expect(server).to receive(:network_interfaces).and_raise(NoMethodError)
      expect(tester.private_ip_for(server)).to eq("unknown")
    end
  end

  describe "#public_ip_for" do
    it "returns the IP address if it exists" do
      access_config     = double("access_config", nat_ip: "4.3.2.1")
      network_interface = double("network_interface", access_configs: [access_config])
      server            = double("server", network_interfaces: [network_interface])

      expect(tester.public_ip_for(server)).to eq("4.3.2.1")
    end

    it "returns 'unknown' if the IP cannot be found" do
      network_interface = double("network_interface")
      server            = double("server", network_interfaces: [network_interface])

      expect(network_interface).to receive(:access_configs).and_raise(NoMethodError)
      expect(tester.public_ip_for(server)).to eq("unknown")
    end
  end

  describe "#valid_disk_size?" do
    it "returns true if the disk is between 10 and 10,000" do
      expect(tester.valid_disk_size?(50)).to eq(true)
    end

    it "returns false if the disk is less than 10" do
      expect(tester.valid_disk_size?(5)).to eq(false)
    end

    it "returns false if the disk is greater than 10,000" do
      expect(tester.valid_disk_size?(20_000)).to eq(false)
    end
  end
end
