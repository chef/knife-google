# frozen_string_literal: true
#
# Author:: Chef Partner Engineering (<partnereng@chef.io>)
# Copyright:: Copyright (c) 2012-2025 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
require "support/shared_examples_for_command_bootstrap"
require "gcewinpass"

describe Chef::Knife::Cloud::GoogleServerCreate do
  let(:tester) { Tester.new }
  let(:command) { described_class.new(["test_instance"]) }
  let(:service) { double("service") }
  let(:server)  { double("server") }

  before do
    allow(command).to receive(:service).and_return(service)
    allow(command).to receive(:server).and_return(server)
  end

  it_behaves_like Chef::Knife::Cloud::BootstrapCommand, described_class.new

  describe "#validate_params!" do
    before do
      allow(command).to receive(:check_for_missing_config_values!)
      allow(command).to receive(:valid_disk_size?).and_return(true)
      allow(command).to receive(:boot_disk_size)
      command.config[:bootstrap_protocol] = "ssh"
      command.config[:connection_protocol] = "ssh"
      command.config[:ssh_identity_file] = "/path/to/file"
      command.config[:connection_port] = "22"
      command.config[:image_os_type] = "windows"
      allow(command).to receive(:preemptible?).and_return(false)
    end

    context "when no instance name has been provided" do
      let(:command) { described_class.new }

      it "raises an exception" do
        expect { command.validate_params! }.to raise_error(RuntimeError, "You must supply an instance name.")
      end
    end

    it "checks for missing config values" do
      expect(command).to receive(:check_for_missing_config_values!).with(:gce_zone, :machine_type, :image, :boot_disk_size, :network)

      command.validate_params!
    end

    it "raises an exception if the boot disk size is not valid" do
      expect(command).to receive(:valid_disk_size?).and_return(false)
      expect { command.validate_params! }.to raise_error(RuntimeError)
    end

    it "raises an exception if the gce_project is missing" do
      ui = double("ui")
      expect(tester).to receive(:ui).and_return(ui)
      expect(ui).to receive(:error).with("The following required parameters are missing: gce_project")
      expect { tester.check_for_missing_config_values! }.to raise_error(RuntimeError)
    end

    it "raises an exception if the image_os_type is missing" do
      command.config.delete(:image_os_type)
      expect { command.validate_params! }.to raise_error(RuntimeError)
    end

    it "raises an exception if the connection_port is missing" do
      command.config.delete(:connection_port)
      expect { command.validate_params! }.to raise_error(RuntimeError)
    end

    it "raises an exception if bootstrap is WinRM but no gcloud user email as supplied" do
      command.config[:connection_protocol] = "winrm"
      expect { command.validate_params! }.to raise_error(RuntimeError)
    end

    it "prints a warning if auto-migrate is true for a preemptible instance" do
      command.config.delete(:bootstrap_protocol)
      allow(command).to receive(:preemptible?).and_return(true)
      command.config[:auto_migrate] = true
      expect(command.ui).to receive(:warn).with("Auto-migrate disabled for preemptible instance")
      command.validate_params!
    end

    it "prints a warning if auto-restart is true for a preemptible instance" do
      command.config.delete(:bootstrap_protocol)
      allow(command).to receive(:preemptible?).and_return(true)
      command.config[:auto_restart] = true
      expect(command.ui).to receive(:warn).with("Auto-restart disabled for preemptible instance")
      command.validate_params!
    end
  end

  describe "#before_bootstrap" do
    before do
      allow(command).to receive(:ip_address_for_bootstrap)
    end

    it "sets the node name to what the user provided if a name was provided" do
      command.config[:chef_node_name] = "my-node"
      command.before_bootstrap

      expect(command.config[:chef_node_name]).to eq("my-node")
    end

    it "sets the node name to the instance name if a node name was not provided" do
      expect(command).to receive(:instance_name).and_return("my-instance")
      command.before_bootstrap

      expect(command.config[:chef_node_name]).to eq("my-instance")
    end

    it "sets the bootstrap IP" do
      expect(command).to receive(:ip_address_for_bootstrap).and_return("1.2.3.4")
      command.before_bootstrap

      expect(command.config[:bootstrap_ip_address]).to eq("1.2.3.4")
    end

    it "sets the password if image_os_type is windows" do
      allow(command.ui).to receive(:msg)
      command.config[:image_os_type] = "windows"
      expect(command).to receive(:reset_windows_password).and_return("new_password")
      command.before_bootstrap

      expect(command.config[:connection_password]).to eq("new_password")
    end
  end

  describe "#get_node_name" do
    it "overrides the original method to return nil" do
      expect(command.get_node_name("name", "prefix")).to eq(nil)
    end
  end

  describe "#project" do
    it "returns the project from the config" do
      command.config[:gce_project] = "test_project"
      expect(command.project).to eq("test_project")
    end
  end

  describe "#zone" do
    it "returns the zone from the config" do
      command.config[:gce_zone] = "test_zone"
      expect(command.zone).to eq("test_zone")
    end
  end

  describe "#email" do
    it "returns the email from the config" do
      command.config[:gce_email] = "test_email"
      expect(command.email).to eq("test_email")
    end
  end

  describe "#preemptible?" do
    it "returns the preemptible setting from the config" do
      command.config[:preemptible] = "test_preempt"
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
      command.config[:auto_migrate] = "test_migrate"
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
      command.config[:auto_restart] = "test_restart"
      expect(command.auto_restart?).to eq("test_restart")
    end
  end

  describe "#ip_address_for_bootstrap" do
    it "returns the public IP by default" do
      command.config[:use_private_ip] = false
      expect(command).to receive(:public_ip_for).and_return("1.2.3.4")
      expect(command.ip_address_for_bootstrap).to eq("1.2.3.4")
    end

    it "returns the private IP if requested by the user" do
      command.config[:use_private_ip] = true
      expect(command).to receive(:private_ip_for).and_return("4.3.2.1")
      expect(command.ip_address_for_bootstrap).to eq("4.3.2.1")
    end

    it "raises an exception if an IP cannot be found" do
      command.config[:use_private_ip] = false
      expect(command).to receive(:public_ip_for).and_return("unknown")
      expect { command.ip_address_for_bootstrap }.to raise_error(RuntimeError)
    end
  end

  describe "#metadata" do
    it "returns a hash of metadata" do
      command.config[:metadata] = ["key1=value1", "key2=value2"]
      expect(command.metadata).to eq({ "key1" => "value1", "key2" => "value2" })
    end
  end

  describe "#boot_disk_size" do
    it "returns the disk size as an integer" do
      command.config[:boot_disk_size] = "20"
      expect(command.boot_disk_size).to eq(20)
    end
  end

  describe "#number_of_local_ssd" do
    it "returns the number of local ssd as an integer" do
      command.config[:number_of_local_ssd] = "5"
      expect(command.number_of_local_ssd).to eq(5)
    end
  end

  describe "#reset_windows_password" do
    it "returns the password from the gcewinpass instance" do
      winpass = double("winpass", new_password: "my_password")
      expect(GoogleComputeWindowsPassword).to receive(:new).and_return(winpass)
      expect(command.reset_windows_password).to eq("my_password")
    end
  end

  describe "local_ssd option is passed on CLI" do
    let(:google_server_create) { Chef::Knife::Cloud::GoogleServerCreate.new(["--gce-local-ssd"]) }
    it "when a local_ssd is present" do
      expect(google_server_create.config[:local_ssd]).to eq(true)
    end
  end

  describe "interface option is passed on CLI" do
    let(:google_server_create) { Chef::Knife::Cloud::GoogleServerCreate.new(["--gce-interface", "nvme"]) }
    it "when a interface is present" do
      expect(google_server_create.config[:interface]).to eq("nvme")
    end
  end

  describe "number_of_local_ssd option is passed on CLI" do
    let(:google_server_create) { Chef::Knife::Cloud::GoogleServerCreate.new(["--gce-number-of-local-ssd", "5"]) }
    it "when a number_of_local_ssd is present" do
      expect(google_server_create.config[:number_of_local_ssd]).to eq("5")
    end
  end
end
