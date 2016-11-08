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

require "chef/knife"
require "chef/knife/cloud/exceptions"
require "chef/knife/cloud/google_service"
require "support/shared_examples_for_service"

shared_examples_for "a paginated list fetcher" do |fetch_method, items_method, *args|
  it "retrieves paginated results from the API" do
    expect(service).to receive(:paginated_results).with(fetch_method, items_method, *args)
    subject
  end

  it "returns the results if they exist" do
    expect(service).to receive(:paginated_results).with(fetch_method, items_method, *args).and_return("results")
    expect(subject).to eq("results")
  end

  it "returns an empty array if there are no results" do
    expect(service).to receive(:paginated_results).with(fetch_method, items_method, *args).and_return(nil)
    expect(subject).to eq([])
  end
end

describe Chef::Knife::Cloud::GoogleService do
  let(:project)        { "test_project" }
  let(:zone)           { "test_zone" }
  let(:wait_time)      { 123 }
  let(:refresh_rate)   { 321 }
  let(:max_pages)      { 456 }
  let(:max_pages_size) { 654 }
  let(:connection)     { double("connection") }

  let(:service) do
    Chef::Knife::Cloud::GoogleService.new(
      project:        project,
      zone:           zone,
      wait_time:      wait_time,
      refresh_rate:   refresh_rate,
      max_pages:      max_pages,
      max_pages_size: max_pages_size
    )
  end

  before do
    service.ui = Chef::Knife::UI.new($stdout, $stderr, $stdin, {})
    allow(service.ui).to receive(:msg)
    allow(service.ui).to receive(:error)
    allow(service).to receive(:connection).and_return(connection)
  end

  describe "#connection" do
    it "returns a properly configured ComputeService" do
      compute_service = double("compute_service")
      client_options  = double("client_options")

      allow(service).to receive(:connection).and_call_original

      expect(Google::Apis::ClientOptions).to receive(:new).and_return(client_options)
      expect(client_options).to receive(:application_name=).with("knife-google")
      expect(client_options).to receive(:application_version=).with(Knife::Google::VERSION)

      expect(Google::Apis::ComputeV1::ComputeService).to receive(:new).and_return(compute_service)
      expect(service).to receive(:authorization).and_return("authorization_object")
      expect(compute_service).to receive(:authorization=).with("authorization_object")
      expect(compute_service).to receive(:client_options=).with(client_options)

      expect(service.connection).to eq(compute_service)
    end
  end

  describe "#authorization" do
    it "returns a Google::Auth authorization object" do
      auth_object = double("auth_object")
      expect(Google::Auth).to receive(:get_application_default).and_return(auth_object)
      expect(service.authorization).to eq(auth_object)
    end
  end

  describe "#create_server" do
    it "creates and returns the created instance" do
      create_instance_obj = double("instance_obj")
      create_options      = { name: "test_instance" }
      instance            = double("instance")

      expect(service).to receive(:validate_server_create_options!).with(create_options)
      expect(service).to receive(:instance_object_for).with(create_options).and_return(create_instance_obj)
      expect(connection).to receive(:insert_instance).with(project, zone, create_instance_obj).and_return("operation_id")
      expect(service).to receive(:wait_for_operation).with("operation_id")
      expect(service).to receive(:wait_for_status).with("RUNNING")
      expect(service).to receive(:get_server).with("test_instance").and_return(instance)

      expect(service.create_server(create_options)).to eq(instance)
    end
  end

  describe "#delete_server" do
    context "when the instance does not exist" do
      before do
        allow(service.ui).to receive(:warn)
        expect(service).to receive(:get_server).and_raise(Google::Apis::ClientError.new("not found"))
      end

      it "prints a warning to the user" do
        expect(service.ui).to receive(:warn).with("Unable to locate instance test_instance in project #{project}, zone #{zone}")

        service.delete_server("test_instance")
      end

      it "does not attempt to delete the instance" do
        expect(connection).not_to receive(:delete_instance)

        service.delete_server("test_instance")
      end
    end

    context "when the instance exists" do
      it "confirms the deletion and deletes the instance" do
        instance = double("instance")
        expect(service).to receive(:get_server).with("test_instance").and_return(instance)
        expect(service).to receive(:server_summary).with(instance)
        expect(service.ui).to receive(:confirm)
        expect(connection).to receive(:delete_instance).with(project, zone, "test_instance").and_return("operation-123")
        expect(service).to receive(:wait_for_operation).with("operation-123")

        service.delete_server("test_instance")
      end
    end
  end

  describe "#get_server" do
    it "returns an instance" do
      expect(connection).to receive(:get_instance).with(project, zone, "test_instance").and_return("instance")
      expect(service.get_server("test_instance")).to eq("instance")
    end
  end

  describe "#list_zones" do
    subject { service.list_zones }
    it_behaves_like "a paginated list fetcher", :list_zones, :items, "test_project"
  end

  describe "#list_disks" do
    subject { service.list_disks }
    it_behaves_like "a paginated list fetcher", :list_disks, :items, "test_project", "test_zone"
  end

  describe "#list_regions" do
    subject { service.list_regions }
    it_behaves_like "a paginated list fetcher", :list_regions, :items, "test_project"
  end

  describe "#list_project_quotas" do
    let(:response) { double("response") }

    before do
      expect(service).to receive(:project).and_return(project)
      expect(connection).to receive(:get_project).with(project).and_return(response)
    end

    it "returns the results if they exist" do
      expect(response).to receive(:quotas).and_return("results")
      expect(service.list_project_quotas).to eq("results")
    end

    it "returns an empty array if there are no results" do
      expect(response).to receive(:quotas).and_return(nil)
      expect(service.list_project_quotas).to eq([])
    end
  end

  describe "#validate_server_create_options!" do
    let(:options) do
      {
        machine_type:  "test_type",
        network:       "test_network",
        subnet:        "test_subnet",
        public_ip:     "public_ip",
        image:         "test_image",
        image_project: "test_image_project",
      }
    end

    before do
      allow(service).to receive(:valid_machine_type?).and_return(true)
      allow(service).to receive(:valid_network?).and_return(true)
      allow(service).to receive(:valid_subnet?).and_return(true)
      allow(service).to receive(:valid_public_ip_setting?).and_return(true)
      allow(service).to receive(:image_search_for).and_return(true)
    end

    it "does not raise an exception when all parameters are supplied and accurate" do
      expect { service.validate_server_create_options!(options) }.not_to raise_error
    end

    it "raises an exception if the machine type is not valid" do
      expect(service).to receive(:valid_machine_type?).with("test_type").and_return(false)
      expect { service.validate_server_create_options!(options) }.to raise_error(RuntimeError)
    end

    it "raises an exception if the network is not valid" do
      expect(service).to receive(:valid_network?).with("test_network").and_return(false)
      expect { service.validate_server_create_options!(options) }.to raise_error(RuntimeError)
    end

    it "raises an exception if the network is not valid" do
      expect(service).to receive(:valid_subnet?).with("test_subnet").and_return(false)
      expect { service.validate_server_create_options!(options) }.to raise_error(RuntimeError)
    end

    it "raises an exception if the public ip setting is not valid" do
      expect(service).to receive(:valid_public_ip_setting?).with("public_ip").and_return(false)
      expect { service.validate_server_create_options!(options) }.to raise_error(RuntimeError)
    end

    it "raises an exception if the image parameters are not valid" do
      expect(service).to receive(:image_search_for).with("test_image", "test_image_project").and_return(nil)
      expect { service.validate_server_create_options!(options) }.to raise_error(RuntimeError)
    end
  end

  describe "#check_api_call" do
    it "returns false if the block raises a ClientError" do
      expect(service.check_api_call { raise Google::Apis::ClientError.new("whoops") }).to eq(false)
    end

    it "raises an exception if the block raises something other than a ClientError" do
      expect { service.check_api_call { raise "whoops" } }.to raise_error(RuntimeError)
    end

    it "returns true if the block does not raise an exception" do
      expect(service.check_api_call { true }).to eq(true)
    end
  end

  describe "#valid_machine_type?" do
    it "returns false if no matchine type was specified" do
      expect(service.valid_machine_type?(nil)).to eq(false)
    end

    it "checks the machine type using check_api_call" do
      expect(connection).to receive(:get_machine_type).with(project, zone, "test_type")
      expect(service).to receive(:check_api_call).and_call_original

      service.valid_machine_type?("test_type")
    end
  end

  describe "#valid_network?" do
    it "returns false if no network was specified" do
      expect(service.valid_network?(nil)).to eq(false)
    end

    it "checks the network using check_api_call" do
      expect(connection).to receive(:get_network).with(project, "test_network")
      expect(service).to receive(:check_api_call).and_call_original

      service.valid_network?("test_network")
    end
  end

  describe "#valid_subnet?" do
    it "returns false if no subnet was specified" do
      expect(service.valid_subnet?(nil)).to eq(false)
    end

    it "checks the network using check_api_call" do
      expect(service).to receive(:region).and_return("test_region")
      expect(connection).to receive(:get_subnetwork).with(project, "test_region", "test_subnet")
      expect(service).to receive(:check_api_call).and_call_original

      service.valid_subnet?("test_subnet")
    end
  end

  describe "#image_exist?" do
    it "checks the image using check_api_call" do
      expect(connection).to receive(:get_image).with("image_project", "image_name")
      expect(service).to receive(:check_api_call).and_call_original

      service.image_exist?("image_project", "image_name")
    end
  end

  describe "#valid_public_ip_setting?" do
    it "returns true if the public_ip is nil" do
      expect(service.valid_public_ip_setting?(nil)).to eq(true)
    end

    it "returns true if the public_ip is ephemeral" do
      expect(service.valid_public_ip_setting?("EPHEMERAL")).to eq(true)
    end

    it "returns true if the public_ip is none" do
      expect(service.valid_public_ip_setting?("NONE")).to eq(true)
    end

    it "returns true if the public_ip is a valid IP address" do
      expect(service).to receive(:valid_ip_address?).with("1.2.3.4").and_return(true)
      expect(service.valid_public_ip_setting?("1.2.3.4")).to eq(true)
    end

    it "returns false if it is not nil, ephemeral, none, or a valid IP address" do
      expect(service).to receive(:valid_ip_address?).with("not_an_ip").and_return(false)
      expect(service.valid_public_ip_setting?("not_an_ip")).to eq(false)
    end
  end

  describe "#valid_ip_address" do
    it "returns false if IPAddr is unable to parse the address" do
      expect(IPAddr).to receive(:new).with("not_an_ip").and_raise(IPAddr::InvalidAddressError)
      expect(service.valid_ip_address?("not_an_ip")).to eq(false)
    end

    it "returns true if IPAddr can parse the address" do
      expect(IPAddr).to receive(:new).with("1.2.3.4")
      expect(service.valid_ip_address?("1.2.3.4")).to eq(true)
    end
  end

  describe "#region" do
    it "returns the region for a given zone" do
      zone_obj = double("zone_obj", region: "/path/to/test_region")
      expect(connection).to receive(:get_zone).with(project, zone).and_return(zone_obj)
      expect(service.region).to eq("test_region")
    end
  end

  describe "#instance_object_for" do
    let(:instance_object) { double("instance_object") }
    let(:options) do
      {
        name:           "test_instance",
        can_ip_forward: "ip_forwarding",
        machine_type:   "test_machine_type",
        metadata:       "test_metadata",
        tags:           "test_tags",
      }
    end

    before do
      expect(service).to receive(:instance_disks_for).with(options).and_return("test_disks")
      expect(service).to receive(:machine_type_url_for).with("test_machine_type").and_return("test_machine_type_url")
      expect(service).to receive(:instance_metadata_for).with("test_metadata").and_return("test_metadata_obj")
      expect(service).to receive(:instance_network_interfaces_for).with(options).and_return("test_network_interfaces")
      expect(service).to receive(:instance_scheduling_for).with(options).and_return("test_scheduling")
      allow(service).to receive(:instance_service_accounts_for).with(options).at_least(:once).and_return("test_service_accounts")
      expect(service).to receive(:instance_tags_for).with("test_tags").and_return("test_tags_obj")
    end

    it "builds and returns a valid object for creating an instance" do
      expect(Google::Apis::ComputeV1::Instance).to receive(:new).and_return(instance_object)
      expect(instance_object).to receive(:name=).with("test_instance")
      expect(instance_object).to receive(:can_ip_forward=).with("ip_forwarding")
      expect(instance_object).to receive(:disks=).with("test_disks")
      expect(instance_object).to receive(:machine_type=).with("test_machine_type_url")
      expect(instance_object).to receive(:metadata=).with("test_metadata_obj")
      expect(instance_object).to receive(:network_interfaces=).with("test_network_interfaces")
      expect(instance_object).to receive(:scheduling=).with("test_scheduling")
      expect(instance_object).to receive(:service_accounts=).with("test_service_accounts")
      expect(instance_object).to receive(:tags=).with("test_tags_obj")

      expect(service.instance_object_for(options)).to eq(instance_object)
    end

    it "does not include service accounts if none exist" do
      expect(service).to receive(:instance_service_accounts_for).with(options).and_return(nil)
      expect(instance_object).not_to receive(:service_accounts=)

      service.instance_object_for(options)
    end
  end

  describe "#instance_disks_for" do

    before do
      expect(service).to receive(:instance_boot_disk_for).with(options).and_return("boot_disk")
    end

    context "when no additional disks are to be attached" do
      let(:options) { { additional_disks: [] } }

      it "returns an array containing only the boot disk" do
        expect(service.instance_disks_for(options)).to eq(%w{boot_disk})
      end
    end

    context "when additional disks are to be attached and they exist" do
      let(:options) { { additional_disks: %w{disk1 disk2} } }

      it "returns an array containing all three disks" do
        disk1 = double("disk1")
        disk2 = double("disk2")
        attached_disk1 = double("attached_disk1")
        attached_disk2 = double("attached_disk2")

        expect(connection).to receive(:get_disk).with(project, zone, "disk1").and_return(disk1)
        expect(connection).to receive(:get_disk).with(project, zone, "disk2").and_return(disk2)
        expect(disk1).to receive(:self_link).and_return("disk1_url")
        expect(disk2).to receive(:self_link).and_return("disk2_url")
        expect(Google::Apis::ComputeV1::AttachedDisk).to receive(:new).and_return(attached_disk1)
        expect(Google::Apis::ComputeV1::AttachedDisk).to receive(:new).and_return(attached_disk2)
        expect(attached_disk1).to receive(:source=).and_return("disk1_url")
        expect(attached_disk2).to receive(:source=).and_return("disk2_url")
        expect(service.instance_disks_for(options)).to eq(["boot_disk", attached_disk1, attached_disk2])
      end
    end

    context "when an additional disk is to be attached but does not exist" do
      let(:options) { { additional_disks: %w{bad_disk} } }

      it "raises an exception" do
        expect(connection).to receive(:get_disk).with(project, zone, "bad_disk").and_raise(Google::Apis::ClientError.new("disk not found"))
        expect(service.ui).to receive(:error).with("Unable to attach disk bad_disk to the instance: disk not found")
        expect { service.instance_disks_for(options) }.to raise_error(Google::Apis::ClientError)
      end
    end
  end

  describe "#instance_boot_disk_for" do
    it "sets up a disk object and returns it" do
      disk    = double("disk")
      params  = double("params")
      options = {
        boot_disk_autodelete: "autodelete_param",
        boot_disk_size:       "disk_size",
        boot_disk_ssd:        "disk_ssd",
        image:                "disk_image",
        image_project:        "disk_image_project",
      }

      expect(service).to receive(:boot_disk_name_for).with(options).and_return("disk_name")
      expect(service).to receive(:boot_disk_type_for).with(options).and_return("disk_type")
      expect(service).to receive(:disk_type_url_for).with("disk_type").and_return("disk_type_url")
      expect(service).to receive(:image_search_for).with("disk_image", "disk_image_project").and_return("source_image")

      expect(Google::Apis::ComputeV1::AttachedDisk).to receive(:new).and_return(disk)
      expect(Google::Apis::ComputeV1::AttachedDiskInitializeParams).to receive(:new).and_return(params)
      expect(disk).to receive(:boot=).with(true)
      expect(disk).to receive(:auto_delete=).with("autodelete_param")
      expect(disk).to receive(:initialize_params=).with(params)
      expect(params).to receive(:disk_name=).with("disk_name")
      expect(params).to receive(:disk_size_gb=).with("disk_size")
      expect(params).to receive(:disk_type=).with("disk_type_url")
      expect(params).to receive(:source_image=).with("source_image")

      expect(service.instance_boot_disk_for(options)).to eq(disk)
    end
  end

  describe "#boot_disk_type_for" do
    it "returns pd-ssd if boot_disk_ssd is true" do
      expect(service.boot_disk_type_for(boot_disk_ssd: true)).to eq("pd-ssd")
    end

    it "returns pd-standard if boot_disk_ssd is false" do
      expect(service.boot_disk_type_for(boot_disk_ssd: false)).to eq("pd-standard")
    end
  end

  describe "#image_search_for" do
    context "when the user supplies an image project" do
      it "returns the image URL based on the image project" do
        expect(service).to receive(:image_url_for).with("test_project", "test_image").and_return("image_url")
        expect(service.image_search_for("test_image", "test_project")).to eq("image_url")
      end
    end

    context "when the user does not supply an image project" do
      context "when the image provided is an alias" do
        it "returns the alias URL" do
          expect(service).to receive(:image_alias_url).with("test_image").and_return("image_alias_url")
          expect(service.image_search_for("test_image", nil)).to eq("image_alias_url")
        end
      end

      context "when the image provided is not an alias" do
        before do
          expect(service).to receive(:image_alias_url).and_return(nil)
        end

        context "when the image exists in the user's project" do
          it "returns the image URL" do
            expect(service).to receive(:image_url_for).with(project, "test_image").and_return("image_url")
            expect(service.image_search_for("test_image", nil)).to eq("image_url")
          end
        end

        context "when the image does not exist in the user's project" do
          before do
            expect(service).to receive(:image_url_for).with(project, "test_image").and_return(nil)
          end

          context "when the image matches a known public project" do
            it "returns the image URL from the public project" do
              expect(service).to receive(:public_project_for_image).with("test_image").and_return("public_project")
              expect(service).to receive(:image_url_for).with("public_project", "test_image").and_return("image_url")
              expect(service.image_search_for("test_image", nil)).to eq("image_url")
            end
          end

          context "when the image does not match a known project" do
            it "returns nil" do
              expect(service).to receive(:public_project_for_image).with("test_image").and_return(nil)
              expect(service).not_to receive(:image_url_for)
              expect(service.image_search_for("test_image", nil)).to eq(nil)
            end
          end
        end
      end
    end
  end

  describe "#image_url_for" do
    it "returns nil if the image does not exist" do
      expect(service).to receive(:image_exist?).with("image_project", "image_name").and_return(false)
      expect(service.image_url_for("image_project", "image_name")).to eq(nil)
    end

    it "returns a properly formatted image URL if the image exists" do
      expect(service).to receive(:image_exist?).with("image_project", "image_name").and_return(true)
      expect(service.image_url_for("image_project", "image_name")).to eq("projects/image_project/global/images/image_name")
    end
  end

  describe "#image_alias_url" do
    context "when the image_alias is not a valid alias" do
      it "returns nil" do
        expect(service.image_alias_url("fake_alias")).to eq(nil)
      end
    end

    context "when the image_alias is a valid alias" do
      before do
        allow(connection).to receive(:list_images).and_return(response)
      end

      context "when the response contains no images" do
        let(:response) { double("response", items: []) }

        it "returns nil" do
          expect(service.image_alias_url("centos-7")).to eq(nil)
        end
      end

      context "when the response contains images but none match the name" do
        let(:image1)   { double("image1", name: "centos-6") }
        let(:image2)   { double("image2", name: "centos-6") }
        let(:image3)   { double("image3", name: "ubuntu-14") }
        let(:response) { double("response", items: [ image1, image2, image3 ]) }

        it "returns nil" do
          expect(service.image_alias_url("centos-7")).to eq(nil)
        end
      end

      context "when the response contains images that match the name" do
        let(:image1)   { double("image1", name: "centos-7-v20160201", self_link: "image1_selflink") }
        let(:image2)   { double("image2", name: "centos-7-v20160301", self_link: "image2_selflink") }
        let(:image3)   { double("image3", name: "centos-6", self_link: "image3_selflink") }
        let(:response) { double("response", items: [ image1, image2, image3 ]) }

        it "returns the link for image2 which is the most recent image" do
          expect(service.image_alias_url("centos-7")).to eq("image2_selflink")
        end
      end
    end
  end

  describe "#boot_disk_name_for" do
    it "returns the boot disk name if supplied by the user" do
      options = { name: "instance_name", boot_disk_name: "disk_name" }
      expect(service.boot_disk_name_for(options)).to eq("disk_name")
    end

    it "returns the instance name if the boot disk name is not supplied" do
      options = { name: "instance_name" }
      expect(service.boot_disk_name_for(options)).to eq("instance_name")
    end
  end

  describe "#machine_type_url_for" do
    it "returns a properly-formatted machine type URL" do
      expect(service.machine_type_url_for("test_type")).to eq("zones/test_zone/machineTypes/test_type")
    end
  end

  describe "#instance_metadata_for" do
    it "returns nil if the passed-in metadata is nil" do
      expect(service.instance_metadata_for(nil)).to eq(nil)
    end

    it "returns nil if the passed-in metadata is empty" do
      expect(service.instance_metadata_for([])).to eq(nil)
    end

    it "returns a properly-formatted metadata object if metadata is passed in" do
      metadata     = { "key1" => "value1", "key2" => "value2" }
      metadata_obj = double("metadata_obj")
      item_1       = double("item_1")
      item_2       = double("item_2")

      expect(Google::Apis::ComputeV1::Metadata).to receive(:new).and_return(metadata_obj)
      expect(Google::Apis::ComputeV1::Metadata::Item).to receive(:new).and_return(item_1)
      expect(Google::Apis::ComputeV1::Metadata::Item).to receive(:new).and_return(item_2)
      expect(item_1).to receive(:key=).with("key1")
      expect(item_1).to receive(:value=).with("value1")
      expect(item_2).to receive(:key=).with("key2")
      expect(item_2).to receive(:value=).with("value2")
      expect(metadata_obj).to receive(:items=).with([item_1, item_2])

      expect(service.instance_metadata_for(metadata)).to eq(metadata_obj)
    end
  end

  describe "#instance_network_interfaces_for" do
    let(:interface) { double("interface" ) }
    let(:options)   { { network: "test_network", public_ip: "public_ip" } }

    before do
      allow(service).to receive(:network_url_for)
      allow(service).to receive(:subnet_url_for)
      allow(service).to receive(:instance_access_configs_for)
      allow(Google::Apis::ComputeV1::NetworkInterface).to receive(:new).and_return(interface)
      allow(interface).to receive(:network=)
      allow(interface).to receive(:subnetwork=)
      allow(interface).to receive(:access_configs=)
    end

    it "creates a network interface object and returns it" do
      expect(Google::Apis::ComputeV1::NetworkInterface).to receive(:new).and_return(interface)
      expect(service.instance_network_interfaces_for(options)).to eq([interface])
    end

    it "sets the network" do
      expect(service).to receive(:network_url_for).with("test_network").and_return("network_url")
      expect(interface).to receive(:network=).with("network_url")
      service.instance_network_interfaces_for(options)
    end

    it "sets the access configs" do
      expect(service).to receive(:instance_access_configs_for).with("public_ip").and_return("access_configs")
      expect(interface).to receive(:access_configs=).with("access_configs")
      service.instance_network_interfaces_for(options)
    end

    it "does not set a subnetwork" do
      expect(service).not_to receive(:subnet_url_for)
      expect(interface).not_to receive(:subnetwork=)
      service.instance_network_interfaces_for(options)
    end

    context "when a subnet exists" do
      let(:options) { { network: "test_network", subnet: "test_subnet", public_ip: "public_ip" } }

      it "sets the subnetwork" do
        expect(service).to receive(:subnet_url_for).with("test_subnet").and_return("subnet_url")
        expect(interface).to receive(:subnetwork=).with("subnet_url")
        service.instance_network_interfaces_for(options)
      end
    end
  end

  describe "#instance_access_configs_for" do
    let(:interface) { double("interface" ) }

    context "for None public_ip" do
      it "empty public_ip none|None|NONE|~" do
        expect(service.instance_access_configs_for("none")).to eq([])

        expect(service.instance_access_configs_for("None")).to eq([])

        expect(service.instance_access_configs_for("NONE")).to eq([])
      end
    end

    context "for valid public_ip" do
      it "valid public_ip" do
        access_config = service.instance_access_configs_for("8.8.8.8")
        expect(access_config.first.nat_ip).to eq("8.8.8.8")
      end
    end

    context "for invalid public_ip" do
      it "empty public_ip none|None|NONE|~" do
        access_config = service.instance_access_configs_for("oh no not a valid IP")
        expect(access_config.first.nat_ip).to eq(nil)
      end
    end
  end

  describe "#network_url_for" do
    it "returns a properly-formatted network URL" do
      expect(service.network_url_for("test_network")).to eq("projects/test_project/global/networks/test_network")
    end
  end

  describe "#subnet_url_for" do
    it "returns a properly-formatted subnet URL" do
      expect(service).to receive(:region).and_return("test_region")
      expect(service.subnet_url_for("test_subnet")).to eq("projects/test_project/regions/test_region/subnetworks/test_subnet")
    end
  end

  describe "#instance_scheduling_for" do
    it "returns a properly-formatted scheduling object" do
      scheduling = double("scheduling")
      options    = { auto_restart: "auto_restart", auto_migrate: "auto_migrate", preemptible: "preempt" }

      expect(service).to receive(:migrate_setting_for).with("auto_migrate").and_return("host_maintenance")
      expect(Google::Apis::ComputeV1::Scheduling).to receive(:new).and_return(scheduling)
      expect(scheduling).to receive(:automatic_restart=).with("auto_restart")
      expect(scheduling).to receive(:on_host_maintenance=).with("host_maintenance")
      expect(scheduling).to receive(:preemptible=).with("preempt")

      expect(service.instance_scheduling_for(options)).to eq(scheduling)
    end
  end

  describe "#migrate_setting_for" do
    it "returns MIGRATE when auto_migrate is true" do
      expect(service.migrate_setting_for(true)).to eq("MIGRATE")
    end

    it "returns TERMINATE when auto_migrate is false" do
      expect(service.migrate_setting_for(false)).to eq("TERMINATE")
    end
  end

  describe "#instance_service_accounts_for" do
    it "returns nil if service_account_scopes is nil" do
      expect(service.instance_service_accounts_for({})).to eq(nil)
    end

    it "returns nil if service_account_scopes is empty" do
      expect(service.instance_service_accounts_for({ service_account_scopes: [] })).to eq(nil)
    end

    it "returns an array containing a properly-formatted service account" do
      service_account = double("service_account")
      options         = { service_account_name: "account_name", service_account_scopes: %w{scope1 scope2} }

      expect(Google::Apis::ComputeV1::ServiceAccount).to receive(:new).and_return(service_account)
      expect(service_account).to receive(:email=).with("account_name")
      expect(service).to receive(:service_account_scope_url).with("scope1").and_return("https://www.googleapis.com/auth/scope1")
      expect(service).to receive(:service_account_scope_url).with("scope2").and_return("https://www.googleapis.com/auth/scope2")
      expect(service_account).to receive(:scopes=).with([
        "https://www.googleapis.com/auth/scope1",
        "https://www.googleapis.com/auth/scope2",
      ])

      expect(service.instance_service_accounts_for(options)).to eq([service_account])
    end
  end

  describe "#service_account_scope_url" do
    it "returns the passed-in scope if it already looks like a scope URL" do
      scope = "https://www.googleapis.com/auth/fake_scope"
      expect(service.service_account_scope_url(scope)).to eq(scope)
    end

    it "returns a properly-formatted scope URL if a short-name or alias is provided" do
      expect(service).to receive(:translate_scope_alias).with("scope_alias").and_return("real_scope")
      expect(service.service_account_scope_url("scope_alias")).to eq("https://www.googleapis.com/auth/real_scope")
    end
  end

  describe "#translate_scope_alias" do
    it "returns a scope for a given alias" do
      expect(service.translate_scope_alias("storage-rw")).to eq("devstorage.read_write")
    end

    it "returns the passed-in scope alias if nothing matches in the alias map" do
      expect(service.translate_scope_alias("fake_scope")).to eq("fake_scope")
    end
  end

  describe "#instance_tags_for" do
    it "returns nil if tags is nil" do
      expect(service.instance_tags_for(nil)).to eq(nil)
    end

    it "returns nil if tags is empty" do
      expect(service.instance_tags_for([])).to eq(nil)
    end

    it "returns a properly-formatted tags object" do
      tags_obj = double("tags_obj")

      expect(Google::Apis::ComputeV1::Tags).to receive(:new).and_return(tags_obj)
      expect(tags_obj).to receive(:items=).with("test_tags")

      expect(service.instance_tags_for("test_tags")).to eq(tags_obj)
    end
  end

  describe "#network_for" do
    it "returns the network name if it exists" do
      interface = double("interface", network: "/some/path/to/default_network")
      instance = double("instance", network_interfaces: [interface])

      expect(service.network_for(instance)).to eq("default_network")
    end

    it "returns 'unknown' if the network cannot be found" do
      instance = double("instance")
      expect(instance).to receive(:network_interfaces).and_raise(NoMethodError)

      expect(service.network_for(instance)).to eq("unknown")
    end
  end

  describe "#machine_type_for" do
    it "returns the machine type name" do
      instance = double("instance", machine_type: "/some/path/to/test_type")
      expect(service.machine_type_for(instance)).to eq("test_type")
    end
  end

  describe "#public_project_for_image" do
    {
      "centos"         => "centos-cloud",
      "container-vm"   => "google-containers",
      "coreos"         => "coreos-cloud",
      "debian"         => "debian-cloud",
      "opensuse-cloud" => "opensuse-cloud",
      "rhel"           => "rhel-cloud",
      "sles"           => "suse-cloud",
      "ubuntu"         => "ubuntu-os-cloud",
      "windows"        => "windows-cloud",
    }.each do |image_name, project_name|
      it "returns project #{project_name} for an image named #{image_name}" do
        expect(service.public_project_for_image(image_name)).to eq(project_name)
      end
    end
  end

  describe "#disk_type_url_for" do
    it "returns a properly-formatted disk type URL" do
      expect(service.disk_type_url_for("disk_type")).to eq("zones/test_zone/diskTypes/disk_type")
    end
  end

  describe "#paginated_results" do
    let(:response)      { double("response") }
    let(:api_method)    { :list_stuff }
    let(:items_method)  { :items }
    let(:args)          { %w{arg1 arg2} }
    let(:max_pages)     { 5 }
    let(:max_page_size) { 100 }

    subject { service.paginated_results(api_method, items_method, *args) }

    before do
      allow(response).to receive(:next_page_token)
      allow(service).to receive(:max_pages).and_return(max_pages)
      allow(service).to receive(:max_page_size).and_return(max_page_size)
    end

    context "when the response has no items" do
      it "returns an empty array" do
        expect(connection).to receive(:list_stuff).with(*args, max_results: max_page_size, page_token: nil).and_return(response)
        expect(response).to receive(:items).and_return(nil)
        expect(subject).to eq([])
      end
    end

    context "when the response has items with no additional pages" do
      it "calls the API once and returns the fetched results" do
        expect(response).to receive(:items).and_return(%w{item1 item2})
        expect(connection).to receive(:list_stuff).with(*args, max_results: max_page_size, page_token: nil).and_return(response)
        expect(subject).to eq(%w{item1 item2})
      end
    end

    context "when the response has items spanning 3 pages" do

      it "calls the API 3 times and returns the results" do
        response1 = double("response1", items: %w{item1 item2}, next_page_token: "page2")
        response2 = double("response2", items: %w{item3 item4}, next_page_token: "page3")
        response3 = double("response3", items: %w{item5 item6}, next_page_token: nil)

        expect(connection).to receive(:list_stuff).with(*args, max_results: max_page_size, page_token: nil).and_return(response1)
        expect(connection).to receive(:list_stuff).with(*args, max_results: max_page_size, page_token: "page2").and_return(response2)
        expect(connection).to receive(:list_stuff).with(*args, max_results: max_page_size, page_token: "page3").and_return(response3)
        expect(subject).to eq(%w{item1 item2 item3 item4 item5 item6})
      end
    end

    context "when the response has items spanning more than max allowed pages" do
      it "only calls the API the maximum allow number of times and returns results" do
        response1 = double("response1", items: %w{item1}, next_page_token: "page2")
        response2 = double("response2", items: %w{item2}, next_page_token: "page3")
        response3 = double("response3", items: %w{item3}, next_page_token: "page4")
        response4 = double("response4", items: %w{item4}, next_page_token: "page5")
        response5 = double("response5", items: %w{item5}, next_page_token: "page6")
        expect(connection).to receive(:list_stuff).with(*args, max_results: max_page_size, page_token: nil).and_return(response1)
        expect(connection).to receive(:list_stuff).with(*args, max_results: max_page_size, page_token: "page2").and_return(response2)
        expect(connection).to receive(:list_stuff).with(*args, max_results: max_page_size, page_token: "page3").and_return(response3)
        expect(connection).to receive(:list_stuff).with(*args, max_results: max_page_size, page_token: "page4").and_return(response4)
        expect(connection).to receive(:list_stuff).with(*args, max_results: max_page_size, page_token: "page5").and_return(response5)
        expect(service.ui).to receive(:warn).with("Max pages (5) reached, but more results exist - truncating results...")
        expect(subject).to eq(%w{item1 item2 item3 item4 item5})
      end
    end
  end

  describe "#wait_for_status" do
    let(:item) { double("item") }

    before do
      allow(service).to receive(:wait_time).and_return(600)
      allow(service).to receive(:refresh_rate).and_return(2)

      # muffle any stdout output from this method
      allow(service).to receive(:print)

      # don"t actually sleep
      allow(service).to receive(:sleep)
    end

    context "when the items completes normally, 3 loops" do
      it "only refreshes the item 3 times" do
        allow(item).to receive(:status).exactly(3).times.and_return("PENDING", "RUNNING", "DONE")

        service.wait_for_status("DONE") { item }
      end
    end

    context "when the item is completed on the first loop" do
      it "only refreshes the item 1 time" do
        allow(item).to receive(:status).once.and_return("DONE")

        service.wait_for_status("DONE") { item }
      end
    end

    context "when the timeout is exceeded" do
      it "prints a warning and exits" do
        allow(Timeout).to receive(:timeout).and_raise(Timeout::Error)
        expect(service.ui).to receive(:error)
          .with("Request did not complete in 600 seconds. Check the Google Cloud Console for more info.")
        expect { service.wait_for_status("DONE") { item } }.to raise_error(SystemExit)
      end
    end

    context "when a non-timeout exception is raised" do
      it "raises the original exception" do
        allow(item).to receive(:status).and_raise(RuntimeError)
        expect { service.wait_for_status("DONE") { item } }.to raise_error(RuntimeError)
      end
    end
  end

  describe "#wait_for_operation" do
    let(:operation) { double("operation", name: "operation-123") }

    it "raises a properly-formatted exception when errors exist" do
      error1 = double("error1", code: "ERROR1", message: "error 1")
      error2 = double("error2", code: "ERROR2", message: "error 2")
      expect(service).to receive(:wait_for_status).with("DONE")
      expect(service).to receive(:operation_errors).with("operation-123").and_return([error1, error2])
      expect(service.ui).to receive(:error).with("#{service.ui.color("ERROR1", :bold)}: error 1")
      expect(service.ui).to receive(:error).with("#{service.ui.color("ERROR2", :bold)}: error 2")

      expect { service.wait_for_operation(operation) }.to raise_error(RuntimeError, "Operation operation-123 failed.")
    end

    it "does not raise an exception if no errors are encountered" do
      expect(service).to receive(:wait_for_status).with("DONE")
      expect(service).to receive(:operation_errors).with("operation-123").and_return([])
      expect(service.ui).not_to receive(:error)

      expect { service.wait_for_operation(operation) }.not_to raise_error
    end
  end

  describe "#zone_operation" do
    it "fetches the operation from the API and returns it" do
      expect(connection).to receive(:get_zone_operation).with(project, zone, "operation-123").and_return("operation")
      expect(service.zone_operation("operation-123")).to eq("operation")
    end
  end

  describe "#operation_errors" do
    let(:operation) { double("operation") }
    let(:error_obj) { double("error_obj") }

    before do
      expect(service).to receive(:zone_operation).with("operation-123").and_return(operation)
    end

    it "returns an empty array if there are no errors" do
      expect(operation).to receive(:error).and_return(nil)
      expect(service.operation_errors("operation-123")).to eq([])
    end

    it "returns the errors from the operation if they exist" do
      expect(operation).to receive(:error).twice.and_return(error_obj)
      expect(error_obj).to receive(:errors).and_return("some errors")
      expect(service.operation_errors("operation-123")).to eq("some errors")
    end
  end
end
