# frozen_string_literal: true
#
# Author:: Paul Rossman (<paulrossman@google.com>)
# Author:: Chef Partner Engineering (<partnereng@chef.io>)
# Copyright:: Copyright 2015-2016 Google Inc., Chef Software, Inc.
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

require "chef/knife"
require "chef/knife/cloud/server/create_command"
require "chef/knife/cloud/server/create_options"
require "chef/knife/cloud/google_service"
require "chef/knife/cloud/google_service_helpers"
require "chef/knife/cloud/google_service_options"

class Chef::Knife::Cloud
  class GoogleServerCreate < ServerCreateCommand
    include GoogleServiceOptions
    include GoogleServiceHelpers
    include ServerCreateOptions

    banner "knife google server create NAME -m MACHINE_TYPE -I IMAGE (options)"

    option :machine_type,
      short:       "-m MACHINE_TYPE",
      long:        "--gce-machine-type MACHINE_TYPE",
      description: "The machine type of server (n1-highcpu-2, n1-highcpu-2-d, etc)"

    option :image,
      short:       "-I IMAGE",
      long:        "--gce-image IMAGE",
      description: "The Image for the server"

    option :image_project,
      long:        "--gce-image-project IMAGE_PROJECT",
      description: "The project-id containing the Image (debian-cloud, centos-cloud, etc)"

    option :boot_disk_name,
      long:        "--gce-boot-disk-name DISK",
      description: "Name of persistent boot disk; default is to use the server name"

    option :boot_disk_size,
      long:        "--gce-boot-disk-size SIZE",
      description: "Size of the persistent boot disk between 10 and 10000 GB, specified in GB; default is '10' GB",
      default:     "10"

    option :boot_disk_ssd,
      long:        "--[no-]gce-boot-disk-ssd",
      description: "Use pd-ssd boot disk; default is pd-standard boot disk",
      boolean:     true,
      default:     false

    option :boot_disk_autodelete,
      long:        "--[no-]gce-boot-disk-autodelete",
      description: "Delete boot disk when server is deleted.",
      boolean:     true,
      default:     true

    option :additional_disks,
      long:        "--gce-additional-disks DISKS",
      short:       "-D DISKS",
      description: "Names of additional disks, comma-separated, to attach to this server (NOTE: this will not create them)",
      proc:        Proc.new { |disks| disks.split(",") },
      default:     []

    option :auto_restart,
      long:        "--[no-]gce-auto-server-restart",
      description: "GCE can automatically restart your server if it is terminated for non-user-initiated reasons; enabled by default.",
      boolean:     true,
      default:     true

    option :auto_migrate,
      long:        "--[no-]gce-auto-server-migrate",
      description: "GCE can migrate your server to other hardware without downtime prior to periodic infrastructure maintenance, otherwise the server is terminated; enabled by default.",
      boolean:     true,
      default:     true

    option :preemptible,
      long:        "--[no-]gce-preemptible",
      description: "Create the instance as a preemptible instance, allowing GCE to shut it down at any time. Defaults to false.",
      boolean:     true,
      default:     false

    option :can_ip_forward,
      long:        "--[no-]gce-can-ip-forward",
      description: "Allow server network forwarding",
      boolean:     true,
      default:     false

    option :network,
      long:        "--gce-network NETWORK",
      description: "The network for this server; default is 'default'",
      default:     "default"

    option :subnet,
      long:        "--gce-subnet SUBNET",
      description: "The name of the subnet in the network on which to deploy the instance"

    option :tags,
      short:       "-T TAG1,TAG2,TAG3",
      long:        "--gce-tags TAG1,TAG2,TAG3",
      description: "Tags for this server",
      proc:        Proc.new { |tags| tags.split(",") },
      default:     []

    option :metadata,
      long:        "--gce-metadata Key=Value[,Key=Value...]",
      description: "Additional metadata for this server",
      proc:        Proc.new { |metadata| metadata.split(",") },
      default:     []

    option :service_account_scopes,
      long:        "--gce-service-account-scopes SCOPE1,SCOPE2,SCOPE3",
      proc:        Proc.new { |service_account_scopes| service_account_scopes.split(",") },
      description: "Service account scopes for this server",
      default:     []

    option :service_account_name,
      long:        "--gce-service-account-name NAME",
      description: "Service account name for this server, typically in the form of '123845678986@project.gserviceaccount.com'; default is 'default'",
      default:     "default"

    option :use_private_ip,
      long:        "--gce-use-private-ip",
      description: "if used, Chef will attempt to bootstrap the device using the private IP; default is disabled (use public IP)",
      boolean:     true,
      default:     false

    option :public_ip,
      long:        "--gce-public-ip IP_ADDRESS",
      description: "EPHEMERAL or static IP address or NONE; default is 'EPHEMERAL'",
      default:     "EPHEMERAL"

    option :gce_email,
      long:        "--gce-email EMAIL_ADDRESS",
      description: "email address of the logged-in Google Cloud user; required for bootstrapping windows hosts"

    deps do
      require "gcewinpass"
    end

    def before_exec_command
      super

      @create_options = {
        name:                   instance_name,
        image:                  locate_config_value(:image),
        image_project:          locate_config_value(:image_project),
        network:                locate_config_value(:network),
        subnet:                 locate_config_value(:subnet),
        public_ip:              locate_config_value(:public_ip),
        auto_migrate:           auto_migrate?,
        auto_restart:           auto_restart?,
        preemptible:            preemptible?,
        boot_disk_autodelete:   locate_config_value(:boot_disk_autodelete),
        boot_disk_name:         locate_config_value(:boot_disk_name),
        boot_disk_size:         boot_disk_size,
        boot_disk_ssd:          locate_config_value(:boot_disk_ssd),
        additional_disks:       locate_config_value(:additional_disks),
        can_ip_forward:         locate_config_value(:can_ip_forward),
        machine_type:           locate_config_value(:machine_type),
        service_account_scopes: locate_config_value(:service_account_scopes),
        service_account_name:   locate_config_value(:service_account_name),
        metadata:               metadata,
        tags:                   locate_config_value(:tags),
      }
    end

    def set_default_config
      # dumb hack for knife-cloud, which expects the user to pass in the WinRM password to use when bootstrapping.
      # We won't know the password until the instance is created and we forceably reset it.
      config[:winrm_password] = "will_change_this_later"
    end

    def validate_params!
      check_for_missing_config_values!(:machine_type, :image, :boot_disk_size, :network)
      raise "You must supply an instance name." if @name_args.first.nil?
      raise "Boot disk size must be between 10 and 10,000" unless valid_disk_size?(boot_disk_size)
      if locate_config_value(:bootstrap_protocol) == "winrm" && locate_config_value(:gce_email).nil?
        raise "Please provide your Google Cloud console email address via --gce-email. " \
          "It is required when resetting passwords on Windows hosts."
      end

      ui.warn("Auto-migrate disabled for preemptible instance") if preemptible? && locate_config_value(:auto_migrate)
      ui.warn("Auto-restart disabled for preemptible instance") if preemptible? && locate_config_value(:auto_restart)
      super
    end

    def before_bootstrap
      super

      config[:chef_node_name] = locate_config_value(:chef_node_name) ? locate_config_value(:chef_node_name) : instance_name
      config[:bootstrap_ip_address] = ip_address_for_bootstrap

      if locate_config_value(:bootstrap_protocol) == "winrm"
        ui.msg("Resetting the Windows login password so the bootstrap can continue...")
        config[:winrm_password] = reset_windows_password
      end
    end

    # overriding this from Chef::Knife::Cloud::ServerCreateCommand.
    #
    # This gets called in validate_params! in that class before our #before_bootstrap
    # is called, in which it randomly generates a node name, which means we never default
    # to the instance name in our #before_bootstrap method. Instead, we'll just nil this
    # and allow our class here to do The Right Thing.
    def get_node_name(_name, _prefix)
      nil
    end

    def project
      locate_config_value(:gce_project)
    end

    def zone
      locate_config_value(:gce_zone)
    end

    def email
      locate_config_value(:gce_email)
    end

    def preemptible?
      locate_config_value(:preemptible)
    end

    def auto_migrate?
      preemptible? ? false : locate_config_value(:auto_migrate)
    end

    def auto_restart?
      preemptible? ? false : locate_config_value(:auto_restart)
    end

    def ip_address_for_bootstrap
      ip = locate_config_value(:use_private_ip) ? private_ip_for(server) : public_ip_for(server)

      raise "Unable to determine instance IP address for bootstrapping" if ip == "unknown"
      ip
    end

    def instance_name
      @name_args.first
    end

    def metadata
      locate_config_value(:metadata).each_with_object({}) do |item, memo|
        key, value = item.split("=")
        memo[key] = value
      end
    end

    def boot_disk_size
      locate_config_value(:boot_disk_size).to_i
    end

    def reset_windows_password
      GoogleComputeWindowsPassword.new(
        project:       project,
        zone:          zone,
        instance_name: instance_name,
        email:         email,
        username:      locate_config_value(:winrm_user),
        debug:         gcewinpass_debug_mode
      ).new_password
    end

    def gcewinpass_debug_mode
      Chef::Config[:log_level] == :debug
    end
  end
end
