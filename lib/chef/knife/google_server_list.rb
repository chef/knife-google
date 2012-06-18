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

require 'stringio'
require 'yajl'
require 'highline'
require 'chef/knife'
require 'chef/json_compat'
require 'tempfile'

require 'chef/knife/google_base'

class Chef
  class Knife
    class GoogleServerList < Knife

      include Knife::GoogleBase

      banner "knife google server list (options)"

      option :project_id,
        :short => "-p PROJECTNAME",
        :long => "--project_id PROJECTNAME",
        :description => "Your Google Compute Project Name",
        :proc => Proc.new { |project| Chef::Config[:knife][:google_project] = project } 

      def h
        @highline ||= HighLine.new
      end

      def run
        unless Chef::Config[:knife][:google_project]
          ui.error("Project ID is a compulsory parameter")
          exit 1
        end
        $stdout.sync = true

        project_id = Chef::Config[:knife][:google_project]
        validate_project(project_id)
        list_instances = exec_shell_cmd("#{@gcompute} listinstances --print_json --project_id=#{project_id}")
        list_instances.run_command

        if not list_instances.stderr.downcase.scan("error").empty?
          ui.error("Failed to list instances. Error: #{error}")
          exit 1
        end
        instances_json = to_json(list_instances.stdout)

        server_list = [
            h.color('ID', :bold), 
            h.color('Name', :bold),
            h.color('PublicIP', :bold),
            h.color('PrivateIP', :bold),
            h.color('OperatingSystem', :bold)
        
        ]

        if not instances_json.has_key?("items")
          exit 0
        end

        instances_json["items"].each do |item|
          server_list << item["id"]
          server_list << item["name"].split("/").last
          private_ip = []
          public_ip = []
          item["networkInterfaces"].each do  |interface| 
            private_ip << interface["networkIP"]
            interface["accessConfigs"].select { |cfg| public_ip << cfg["natIP"] }
          end

          server_list << public_ip.join(",")
          server_list << private_ip.join(",")
          server_list << item["image"].split("/").last
        end

        puts h.list(server_list, :columns_across, 5)

      end
    end
  end
end
