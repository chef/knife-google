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
require "chef/knife/google_server_create"
require "support/shared_examples_for_command"
require "gcewinpass"

describe Chef::Knife::Cloud::GoogleServerCreate do
  let(:command) { described_class.new(["test_instance"]) }
  let(:service) { double("service") }
  let(:server)  { double("server") }

  before do
    allow(command).to receive(:service).and_return(service)
    allow(command).to receive(:server).and_return(server)
  end

  it_behaves_like Chef::Knife::Cloud::Command, described_class.new

  describe "#validate_params!" do
    before do
      allow(command).to receive(:check_for_missing_config_values!)
      allow(command).to receive(:valid_disk_size?).and_return(true)
      allow(command).to receive(:boot_disk_size)
      allow(command).to receive(:locate_config_value).with(:bootstrap_protocol).and_return("ssh")
      allow(command).to receive(:locate_config_value).with(:identity_file).and_return("/path/to/file")
      allow(command).to receive(:locate_config_value).with(:auto_migrate)
      allow(command).to receive(:locate_config_value).with(:auto_restart)
      allow(command).to receive(:locate_config_value).with(:chef_node_name)
      allow(command).to receive(:locate_config_value).with(:chef_node_name_prefix)
      allow(command).to receive(:preemptible?).and_return(false)
    end

    context "when no instance name has been provided" do
      let(:command) { described_class.new }

      it "raises an exception" do
        expect { command.validate_params! }.to raise_error(RuntimeError, "You must supply an instance name.")
      end
    end

    it "checks for missing config values" do
      expect(command).to receive(:check_for_missing_config_values!).with(:machine_type, :image, :boot_disk_size, :network)

      command.validate_params!
    end

    it "raises an exception if the boot disk size is not valid" do
      expect(command).to receive(:valid_disk_size?).and_return(false)
      expect { command.validate_params! }.to raise_error(RuntimeError)
    end

    it "raises an exception if bootstrap is WinRM but no gcloud user email as supplied" do
      expect(command).to receive(:locate_config_value).with(:bootstrap_protocol).and_return("winrm")
      expect(command).to receive(:locate_config_value).with(:gce_email).and_return(nil)
      expect { command.validate_params! }.to raise_error(RuntimeError)
    end

    it "prints a warning if auto-migrate is true for a preemptible instance" do
      allow(command).to receive(:preemptible?).and_return(true)
      allow(command).to receive(:locate_config_value).with(:auto_migrate).and_return(true)
      expect(command.ui).to receive(:warn).with("Auto-migrate disabled for preemptible instance")
      command.validate_params!
    end

    it "prints a warning if auto-restart is true for a preemptible instance" do
      allow(command).to receive(:preemptible?).and_return(true)
      allow(command).to receive(:locate_config_value).with(:auto_restart).and_return(true)
      expect(command.ui).to receive(:warn).with("Auto-restart disabled for preemptible instance")
      command.validate_params!
    end
  end

  describe "#before_bootstrap" do
    before do
      allow(command).to receive(:ip_address_for_bootstrap)
      allow(command).to receive(:locate_config_value)
    end

    it "sets the node name to what the user provided if a name was provided" do
      expect(command).to receive(:locate_config_value).with(:chef_node_name).at_least(:once).and_return("my-node")
      command.before_bootstrap

      expect(command.config[:chef_node_name]).to eq("my-node")
    end

    it "sets the node name to the instance name if a node name was not provided" do
      expect(command).to receive(:locate_config_value).with(:chef_node_name).at_least(:once).and_return(nil)
      expect(command).to receive(:instance_name).and_return("my-instance")
      command.before_bootstrap

      expect(command.config[:chef_node_name]).to eq("my-instance")
    end

    it "sets the bootstrap IP" do
      expect(command).to receive(:ip_address_for_bootstrap).and_return("1.2.3.4")
      command.before_bootstrap

      expect(command.config[:bootstrap_ip_address]).to eq("1.2.3.4")
    end

    it "sets the winrm password if winrm is used" do
      allow(command.ui).to receive(:msg)
      expect(command).to receive(:locate_config_value).with(:bootstrap_protocol).at_least(:once).and_return("winrm")
      expect(command).to receive(:reset_windows_password).and_return("new_password")
      command.before_bootstrap

      expect(command.config[:winrm_password]).to eq("new_password")
    end
  end

  describe "#get_node_name" do
    it "overrides the original method to return nil" do
      expect(command.get_node_name("name", "prefix")).to eq(nil)
    end
  end

  describe "#project" do
    it "returns the project from the config" do
      expect(command).to receive(:locate_config_value).with(:gce_project).and_return("test_project")
      expect(command.project).to eq("test_project")
    end
  end

  describe "#zone" do
    it "returns the zone from the config" do
      expect(command).to receive(:locate_config_value).with(:gce_zone).and_return("test_zone")
      expect(command.zone).to eq("test_zone")
    end
  end

  describe "#email" do
    it "returns the email from the config" do
      expect(command).to receive(:locate_config_value).with(:gce_email).and_return("test_email")
      expect(command.email).to eq("test_email")
    end
  end

  describe "#preemptible?" do
    it "returns the preemptible setting from the config" do
      expect(command).to receive(:locate_config_value).with(:preemptible).and_return("test_preempt")
      expect(command.preemptible?).to eq("test_preempt")
    end
  end

  describe "#auto_migrate?" do
    it "returns false if the instance is preemptible" do
      expect(command).to receive(:preemptible?).and_return(true)
      expect(command.auto_migrate?).to eq(false)
    end

    it "returns the setting from the config if preemptible is false" do
      expect(command).to receive(:preemptible?).and_return(false)
      expect(command).to receive(:locate_config_value).with(:auto_migrate).and_return("test_migrate")
      expect(command.auto_migrate?).to eq("test_migrate")
    end
  end

  describe "#auto_restart?" do
    it "returns false if the instance is preemptible" do
      expect(command).to receive(:preemptible?).and_return(true)
      expect(command.auto_restart?).to eq(false)
    end

    it "returns the setting from the config if preemptible is false" do
      expect(command).to receive(:preemptible?).and_return(false)
      expect(command).to receive(:locate_config_value).with(:auto_restart).and_return("test_restart")
      expect(command.auto_restart?).to eq("test_restart")
    end
  end

  describe "#ip_address_for_bootstrap" do
    it "returns the public IP by default" do
      expect(command).to receive(:locate_config_value).with(:use_private_ip).and_return(false)
      expect(command).to receive(:public_ip_for).and_return("1.2.3.4")
      expect(command.ip_address_for_bootstrap).to eq("1.2.3.4")
    end

    it "returns the private IP if requested by the user" do
      expect(command).to receive(:locate_config_value).with(:use_private_ip).and_return(true)
      expect(command).to receive(:private_ip_for).and_return("4.3.2.1")
      expect(command.ip_address_for_bootstrap).to eq("4.3.2.1")
    end

    it "raises an exception if an IP cannot be found" do
      expect(command).to receive(:locate_config_value).with(:use_private_ip).and_return(false)
      expect(command).to receive(:public_ip_for).and_return("unknown")
      expect { command.ip_address_for_bootstrap }.to raise_error(RuntimeError)
    end
  end

  describe "#metadata" do
    it "returns a hash of metadata" do
      expect(command).to receive(:locate_config_value).with(:metadata).and_return(["key1=value1", "key2=value2"])
      expect(command.metadata).to eq({ "key1" => "value1", "key2" => "value2" })
    end
  end

  describe "#boot_disk_size" do
    it "returns the disk size as an integer" do
      expect(command).to receive(:locate_config_value).with(:boot_disk_size).and_return("20")
      expect(command.boot_disk_size).to eq(20)
    end
  end

  describe "#reset_windows_password" do
    it "returns the password from the gcewinpass instance" do
      winpass = double("winpass", new_password: "my_password")
      expect(GoogleComputeWindowsPassword).to receive(:new).and_return(winpass)
      expect(command.reset_windows_password).to eq("my_password")
    end
  end
end
