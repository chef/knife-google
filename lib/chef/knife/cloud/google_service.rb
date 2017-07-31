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

require "chef/knife/cloud/exceptions"
require "chef/knife/cloud/service"
require "chef/knife/cloud/helpers"
require "chef/knife/cloud/google_service_helpers"
require "google/apis/compute_v1"
require "ipaddr"
require "knife-google/version"

class Chef::Knife::Cloud
  class GoogleService < Service
    include Chef::Knife::Cloud::GoogleServiceHelpers

    attr_reader :project, :zone, :wait_time, :refresh_rate, :max_pages, :max_page_size

    SCOPE_ALIAS_MAP = {
      "bigquery"           => "bigquery",
      "cloud-platform"     => "cloud-platform",
      "compute-ro"         => "compute.readonly",
      "compute-rw"         => "compute",
      "datastore"          => "datastore",
      "logging-write"      => "logging.write",
      "monitoring"         => "monitoring",
      "monitoring-write"   => "monitoring.write",
      "service-control"    => "servicecontrol",
      "service-management" => "service.management",
      "sql"                => "sqlservice",
      "sql-admin"          => "sqlservice.admin",
      "storage-full"       => "devstorage.full_control",
      "storage-ro"         => "devstorage.read_only",
      "storage-rw"         => "devstorage.read_write",
      "taskqueue"          => "taskqueue",
      "useraccounts-ro"    => "cloud.useraccounts.readonly",
      "useraccounts-rw"    => "cloud.useraccounts",
      "userinfo-email"     => "userinfo.email",
    }

    IMAGE_ALIAS_MAP = {
      "centos-6"           => { project: "centos-cloud",      prefix: "centos-6" },
      "centos-7"           => { project: "centos-cloud",      prefix: "centos-7" },
      "container-vm"       => { project: "google-containers", prefix: "container-vm" },
      "coreos"             => { project: "coreos-cloud",      prefix: "coreos-stable" },
      "debian-7"           => { project: "debian-cloud",      prefix: "debian-7-wheezy" },
      "debian-7-backports" => { project: "debian-cloud",      prefix: "backports-debian-7-wheezy" },
      "debian-8"           => { project: "debian-cloud",      prefix: "debian-8-jessie" },
      "opensuse-13"        => { project: "opensuse-cloud",    prefix: "opensuse-13" },
      "rhel-6"             => { project: "rhel-cloud",        prefix: "rhel-6" },
      "rhel-7"             => { project: "rhel-cloud",        prefix: "rhel-7" },
      "sles-11"            => { project: "suse-cloud",        prefix: "sles-11" },
      "sles-12"            => { project: "suse-cloud",        prefix: "sles-12" },
      "ubuntu-12-04"       => { project: "ubuntu-os-cloud",   prefix: "ubuntu-1204-precise" },
      "ubuntu-1204-lts"    => { project: "ubuntu-os-cloud",   prefix: "ubuntu-1204-precise" },
      "ubuntu-14-04"       => { project: "ubuntu-os-cloud",   prefix: "ubuntu-1404-trusty" },
      "ubuntu-1404-lts"    => { project: "ubuntu-os-cloud",   prefix: "ubuntu-1404-trusty" },
      "ubuntu-15-04"       => { project: "ubuntu-os-cloud",   prefix: "ubuntu-1504-vivid" },
      "ubuntu-15-10"       => { project: "ubuntu-os-cloud",   prefix: "ubuntu-1510-wily" },
      "ubuntu-16-04"       => { project: "ubuntu-os-cloud",   prefix: "ubuntu-1604-xenial" },
      "ubuntu-1604-lts"    => { project: "ubuntu-os-cloud",   prefix: "ubuntu-1604-xenial" },
      "windows-2008-r2"    => { project: "windows-cloud",     prefix: "windows-server-2008-r2" },
      "windows-2012-r2"    => { project: "windows-cloud",     prefix: "windows-server-2012-r2" },
    }

    def initialize(options = {})
      @project       = options[:project]
      @zone          = options[:zone]
      @wait_time     = options[:wait_time]
      @refresh_rate  = options[:refresh_rate]
      @max_pages     = options[:max_pages]
      @max_page_size = options[:max_page_size]
    end

    def connection
      return @connection unless @connection.nil?

      @connection = Google::Apis::ComputeV1::ComputeService.new
      @connection.authorization = authorization
      @connection.client_options = Google::Apis::ClientOptions.new.tap do |opts|
        opts.application_name    = "knife-google"
        opts.application_version = Knife::Google::VERSION
      end

      @connection
    end

    def authorization
      @authorization ||= Google::Auth.get_application_default(
        [
          "https://www.googleapis.com/auth/cloud-platform",
          "https://www.googleapis.com/auth/compute",
        ]
      )
    end

    def create_server(options = {})
      validate_server_create_options!(options)

      ui.msg("Creating instance...")

      instance_object = instance_object_for(options)
      wait_for_operation(connection.insert_instance(project, zone, instance_object))
      wait_for_status("RUNNING") { get_server(options[:name]) }

      ui.msg("Instance created!")

      get_server(options[:name])
    end

    def delete_server(instance_name)
      begin
        instance = get_server(instance_name)
      rescue Google::Apis::ClientError
        ui.warn("Unable to locate instance #{instance_name} in project #{project}, zone #{zone}")
        return
      end

      server_summary(instance)
      ui.confirm("Do you really want to delete this instance")

      ui.msg("Deleting instance #{instance_name}...")

      wait_for_operation(connection.delete_instance(project, zone, instance_name))

      ui.msg("Instance #{instance_name} deleted successfully.")
    end

    def get_server(instance_name)
      connection.get_instance(project, zone, instance_name)
    end

    def create_disk(name, size, type, source_image = nil)
      disk = Google::Apis::ComputeV1::Disk.new
      disk.name    = name
      disk.size_gb = size
      disk.type    = disk_type_url_for(type)

      ui.msg("Creating a #{size} GB disk named #{name}...")

      wait_for_operation(connection.insert_disk(project, zone, disk, source_image: source_image))

      ui.msg("Waiting for disk to be ready...")

      wait_for_status("READY") { connection.get_disk(project, zone, name) }

      ui.msg("Disk created successfully.")
    end

    def delete_disk(name)
      begin
        connection.get_disk(project, zone, name)
      rescue Google::Apis::ClientError
        ui.warn("Unable to locate disk #{name} in project #{project}, zone #{zone}")
        return
      end

      ui.confirm("Do you really want to delete disk #{name}")

      ui.msg("Deleting disk #{name}...")
      wait_for_operation(connection.delete_disk(project, zone, name))
      ui.msg("Disk #{name} deleted successfully.")
    end

    def list_servers
      instances = paginated_results(:list_instances, :items, project, zone)
      return [] if instances.nil?

      instances.each_with_object([]) do |instance, memo|
        memo << OpenStruct.new(
          name:         instance.name,
          status:       instance.status,
          machine_type: machine_type_for(instance),
          network:      network_for(instance),
          private_ip:   private_ip_for(instance),
          public_ip:    public_ip_for(instance)
        )
      end
    end

    def list_zones
      paginated_results(:list_zones, :items, project) || []
    end

    def list_disks
      paginated_results(:list_disks, :items, project, zone) || []
    end

    def list_regions
      paginated_results(:list_regions, :items, project) || []
    end

    def list_project_quotas
      connection.get_project(project).quotas || []
    end

    def validate_server_create_options!(options)
      raise "Invalid machine type: #{options[:machine_type]}" unless valid_machine_type?(options[:machine_type])
      raise "Invalid network: #{options[:network]}" unless valid_network?(options[:network])
      raise "Invalid subnet: #{options[:subnet]}" if options[:subnet] && !valid_subnet?(options[:subnet])
      raise "Invalid Public IP setting: #{options[:public_ip]}" unless valid_public_ip_setting?(options[:public_ip])
      raise "Invalid image: #{options[:image]} - check your image name, or set an image project if needed" if boot_disk_source_image(options[:image], options[:image_project]).nil?
    end

    def check_api_call
      yield
    rescue Google::Apis::ClientError
      false
    else
      true
    end

    def valid_machine_type?(machine_type)
      return false if machine_type.nil?
      check_api_call { connection.get_machine_type(project, zone, machine_type) }
    end

    def valid_network?(network)
      return false if network.nil?
      check_api_call { connection.get_network(project, network) }
    end

    def valid_subnet?(subnet)
      return false if subnet.nil?
      check_api_call { connection.get_subnetwork(project, region, subnet) }
    end

    def image_exist?(image_project, image_name)
      check_api_call { connection.get_image(image_project, image_name) }
    end

    def valid_public_ip_setting?(public_ip)
      case
      when public_ip.nil? || public_ip.match(/(ephemeral|none)/i)
        true
      when valid_ip_address?(public_ip)
        true
      else
        false
      end
    end

    def valid_ip_address?(ip_address)
      IPAddr.new(ip_address)
    rescue IPAddr::InvalidAddressError
      false
    else
      true
    end

    def region
      @region ||= connection.get_zone(project, zone).region.split("/").last
    end

    def instance_object_for(options)
      inst_obj                    = Google::Apis::ComputeV1::Instance.new
      inst_obj.name               = options[:name]
      inst_obj.can_ip_forward     = options[:can_ip_forward]
      inst_obj.disks              = instance_disks_for(options)
      inst_obj.machine_type       = machine_type_url_for(options[:machine_type])
      inst_obj.metadata           = instance_metadata_for(options[:metadata])
      inst_obj.network_interfaces = instance_network_interfaces_for(options)
      inst_obj.scheduling         = instance_scheduling_for(options)
      inst_obj.service_accounts   = instance_service_accounts_for(options) unless instance_service_accounts_for(options).nil?
      inst_obj.tags               = instance_tags_for(options[:tags])

      inst_obj
    end

    def instance_disks_for(options)
      disks = []
      disks << instance_boot_disk_for(options)
      options[:additional_disks].each do |disk_name|
        begin
          disk = connection.get_disk(project, zone, disk_name)
        rescue Google::Apis::ClientError => e
          ui.error("Unable to attach disk #{disk_name} to the instance: #{e.message}")
          raise
        end

        disks << Google::Apis::ComputeV1::AttachedDisk.new.tap { |x| x.source = disk.self_link }
      end

      disks
    end

    def instance_boot_disk_for(options)
      disk = Google::Apis::ComputeV1::AttachedDisk.new
      params = Google::Apis::ComputeV1::AttachedDiskInitializeParams.new

      disk.boot           = true
      disk.auto_delete    = options[:boot_disk_autodelete]
      params.disk_name    = boot_disk_name_for(options)
      params.disk_size_gb = options[:boot_disk_size]
      params.disk_type    = disk_type_url_for(boot_disk_type_for(options))
      params.source_image = boot_disk_source_image(options[:image], options[:image_project])

      disk.initialize_params = params
      disk
    end

    def boot_disk_type_for(options)
      options[:boot_disk_ssd] ? "pd-ssd" : "pd-standard"
    end

    def boot_disk_source_image(image, image_project)
      @boot_disk_source ||= image_search_for(image, image_project)
    end

    def image_search_for(image, image_project)
      # if the user provided an image_project, assume they want it, no questions asked
      unless image_project.nil?
        ui.msg("Searching project #{image_project} for image #{image}")
        return image_url_for(image_project, image)
      end

      # no image project has been provided. Check to see if the image is a known alias.
      alias_url = image_alias_url(image)
      unless alias_url.nil?
        ui.msg("image #{image} is a known alias - using image URL: #{alias_url}")
        return alias_url
      end

      # Doesn't match an alias. Let's check the user's project for the image.
      url = image_url_for(project, image)
      unless url.nil?
        ui.msg("Located image #{image} in project #{project} - using image URL: #{url}")
        return url
      end

      # Image not found in user's project. Is there a public project this image might exist in?
      public_project = public_project_for_image(image)
      if public_project
        ui.msg("Searching public image project #{public_project} for image #{image}")
        return image_url_for(public_project, image)
      end

      # No image in user's project or public project, so it doesn't exist.
      ui.error("Image search failed for image #{image} - no suitable image located")
      nil
    end

    def image_url_for(image_project, image_name)
      return "projects/#{image_project}/global/images/#{image_name}" if image_exist?(image_project, image_name)
    end

    def image_alias_url(image_alias)
      return unless IMAGE_ALIAS_MAP.key?(image_alias)

      image_project = IMAGE_ALIAS_MAP[image_alias][:project]
      image_prefix  = IMAGE_ALIAS_MAP[image_alias][:prefix]

      latest_image = connection.list_images(image_project).items
        .select { |image| image.name.start_with?(image_prefix) }
        .sort_by(&:name)
        .last

      return if latest_image.nil?

      latest_image.self_link
    end

    def boot_disk_name_for(options)
      options[:boot_disk_name].nil? ? options[:name] : options[:boot_disk_name]
    end

    def machine_type_url_for(machine_type)
      "zones/#{zone}/machineTypes/#{machine_type}"
    end

    def instance_metadata_for(metadata)
      return if metadata.nil? || metadata.empty?

      metadata_obj = Google::Apis::ComputeV1::Metadata.new
      metadata_obj.items = metadata.each_with_object([]) do |(k, v), memo|
        metadata_item       = Google::Apis::ComputeV1::Metadata::Item.new
        metadata_item.key   = k
        metadata_item.value = v

        memo << metadata_item
      end

      metadata_obj
    end

    def instance_network_interfaces_for(options)
      interface = Google::Apis::ComputeV1::NetworkInterface.new
      interface.network = network_url_for(options[:network])
      interface.subnetwork = subnet_url_for(options[:subnet]) if options[:subnet]
      interface.access_configs = instance_access_configs_for(options[:public_ip])

      Array(interface)
    end

    def instance_access_configs_for(public_ip)
      return [] if public_ip.nil? || public_ip.match(/none/i)

      access_config = Google::Apis::ComputeV1::AccessConfig.new
      access_config.name = "External NAT"
      access_config.type = "ONE_TO_ONE_NAT"
      access_config.nat_ip = public_ip if valid_ip_address?(public_ip)

      Array(access_config)
    end

    def network_url_for(network)
      "projects/#{project}/global/networks/#{network}"
    end

    def subnet_url_for(subnet)
      "projects/#{project}/regions/#{region}/subnetworks/#{subnet}"
    end

    def instance_scheduling_for(options)
      scheduling = Google::Apis::ComputeV1::Scheduling.new
      scheduling.automatic_restart   = options[:auto_restart].to_s
      scheduling.on_host_maintenance = migrate_setting_for(options[:auto_migrate])
      scheduling.preemptible         = options[:preemptible].to_s

      scheduling
    end

    def migrate_setting_for(auto_migrate)
      auto_migrate ? "MIGRATE" : "TERMINATE"
    end

    def instance_service_accounts_for(options)
      return if options[:service_account_scopes].nil? || options[:service_account_scopes].empty?

      service_account = Google::Apis::ComputeV1::ServiceAccount.new
      service_account.email  = options[:service_account_name]
      service_account.scopes = options[:service_account_scopes].map { |scope| service_account_scope_url(scope) }

      Array(service_account)
    end

    def service_account_scope_url(scope)
      return scope if scope.start_with?("https://www.googleapis.com/auth/")
      "https://www.googleapis.com/auth/#{translate_scope_alias(scope)}"
    end

    def translate_scope_alias(scope_alias)
      SCOPE_ALIAS_MAP.fetch(scope_alias, scope_alias)
    end

    def instance_tags_for(tags)
      return if tags.nil? || tags.empty?

      tag_obj = Google::Apis::ComputeV1::Tags.new
      tag_obj.items = tags

      tag_obj
    end

    def network_for(instance)
      instance.network_interfaces.first.network.split("/").last
    rescue NoMethodError
      "unknown"
    end

    def machine_type_for(instance)
      instance.machine_type.split("/").last
    end

    def server_summary(server, _columns_with_info = nil)
      msg_pair("Instance Name", server.name)
      msg_pair("Status", server.status)
      msg_pair("Machine Type", machine_type_for(server))
      msg_pair("Project", project)
      msg_pair("Zone", zone)
      msg_pair("Network", network_for(server))
      msg_pair("Private IP", private_ip_for(server))
      msg_pair("Public IP", public_ip_for(server))
    end

    def public_project_for_image(image)
      case image
      when /centos/
        "centos-cloud"
      when /container-vm/
        "google-containers"
      when /coreos/
        "coreos-cloud"
      when /debian/
        "debian-cloud"
      when /opensuse-cloud/
        "opensuse-cloud"
      when /rhel/
        "rhel-cloud"
      when /sles/
        "suse-cloud"
      when /ubuntu/
        "ubuntu-os-cloud"
      when /windows/
        "windows-cloud"
      end
    end

    def disk_type_url_for(type)
      "zones/#{zone}/diskTypes/#{type}"
    end

    def paginated_results(api_method, items_method, *args)
      items      = []
      next_token = nil
      loop_num   = 0

      loop do
        loop_num += 1

        response       = connection.send(api_method.to_sym, *args, max_results: max_page_size, page_token: next_token)
        response_items = response.send(items_method.to_sym)

        break if response_items.nil?

        items += response_items

        next_token = response.next_page_token
        break if next_token.nil?

        if loop_num >= max_pages
          ui.warn("Max pages (#{max_pages}) reached, but more results exist - truncating results...")
          break
        end
      end

      items
    end

    def wait_for_status(requested_status)
      last_status = ""

      begin
        Timeout.timeout(wait_time) do
          loop do
            item = yield
            current_status = item.status

            if current_status == requested_status
              print "\n"
              break
            end

            if last_status == current_status
              print "."
            else
              last_status = current_status
              print "\n"
              print "Current status: #{current_status}."
            end

            sleep refresh_rate
          end
        end
      rescue Timeout::Error
        ui.msg("")
        ui.error("Request did not complete in #{wait_time} seconds. Check the Google Cloud Console for more info.")
        exit 1
      end
    end

    def wait_for_operation(operation)
      operation_name = operation.name

      wait_for_status("DONE") { zone_operation(operation_name) }

      errors = operation_errors(operation_name)
      return if errors.empty?

      errors.each do |error|
        ui.error("#{ui.color(error.code, :bold)}: #{error.message}")
      end

      raise "Operation #{operation_name} failed."
    end

    def zone_operation(operation_name)
      connection.get_zone_operation(project, zone, operation_name)
    end

    def operation_errors(operation_name)
      operation = zone_operation(operation_name)
      return [] if operation.error.nil?

      operation.error.errors
    end
  end
end
