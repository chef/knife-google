# Author:: Chirag Jog (<chiragj@websym.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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
require 'highline'

require 'stringio'
require 'yajl'
require 'highline'
require 'chef/knife'
require 'chef/json_compat'
require 'tempfile'

require 'chef/knife/google_base'

class Chef
  class Knife
    class GoogleFlavorList < Knife

      deps do
        require 'chef/knife/google_base'
        Chef::Knife.load_deps
      end

      include Knife::GoogleBase

      banner "knife google flavor list PROJECT_ID (options)"

      option :project_id,
        :short => "-p PROJECT_ID",
        :long => "--project_id PROJECT_ID",
        :description => "The Google Compute Engine project identifier",
        :proc => Proc.new { |project| Chef::Config[:knife][:google_project] = project }

      def h
        @highline ||= HighLine.new
      end

      def run
        unless Chef::Config[:knife][:google_project]
          ui.error("A Google Compute Engine project identifier is required")
          exit 1
        end
        $stdout.sync = true

        project_id = Chef::Config[:knife][:google_project]
        validate_project(project_id)
        list_flavor = exec_shell_cmd("#{@gcompute} listmachinetypes --print_json --project=#{project_id}")
        Chef::Log.debug 'Executing ' + list_flavor.command
        list_flavor.run_command

        if not list_flavor.stderr.downcase.scan("error").empty?
          ui.error("Failed to list flavors. Error: #{error}")
          exit 1
        end
        flavor_json = to_json(list_flavor.stdout)

        flavor_list = [
            h.color('ID', :bold),
            h.color('Name', :bold),
            h.color('CPU', :bold),
            h.color('Memory(MB)', :bold),
        ]

        if not flavor_json.has_key?("items")
          exit 0
        end

        flavor_json["items"].each do |item|
          flavor_list << item["id"]
          flavor_list << item["name"].split("/").last
          flavor_list << item["guestCpus"].to_s
          flavor_list << item["memoryMb"].to_s
        end
        puts h.list(flavor_list, :columns_across, 4)

      end
    end
  end
end
