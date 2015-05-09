# Copyright 2015 Google Inc. All Rights Reserved.
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

require 'chef/knife/google_base'

class Chef
  class Knife
    class GoogleServerDelete < Knife

      include Knife::GoogleBase

      deps do
        require 'chef/api_client'
      end

      banner "knife google server delete SERVER [SERVER] (options)"

      attr_reader :instances

      option :gce_zone,
        :short => "-Z ZONE",
        :long => "--gce-zone ZONE",
        :description => "The Zone for this instance",
        :proc => Proc.new { |key| Chef::Config[:knife][:gce_zone] = key }

      option :purge,
        :short => "-P",
        :long => "--purge",
        :boolean => true,
        :default => false,
        :description => "In addition to deleting the GCE instance itself, delete corresponding node and client on the Chef Server."

      # Taken from knife-ec2 plugin, for rational check the following link
      # https://github.com/opscode/knife-ec2/blob/master/lib/chef/knife/ec2_server_delete.rb#L48
      def destroy_item(klass, name, type_name)
        begin
          object = klass.load(name)
          object.destroy
          ui.warn("Deleted #{type_name} #{name}")
        rescue Net::HTTPServerException
          ui.warn("Could not find a #{type_name} named #{name} to delete!")
        end
      end

      def run
        @name_args.each do |instance_name|
          begin
            ui.confirm("Delete the instance '#{config[:zone]}:#{instance_name}'")
            result = client.execute(
              :api_method => compute.instance.delete,
              :parameters => {:project => config[:gce_project], :zone => config[:gce_zone], :instance => instance_name})
            ui.warn("Instance '#{config[:zone]}:#{instance_name}' deleted") if result.status == 200
          rescue
            body = MultiJson.load(result.body, :symbolize_keys => true)
            ui.error("#{body[:error][:message]}")
            raise
          end
          if config[:purge]
            destroy_item(Chef::Node, instance_name, "node")
            destroy_item(Chef::ApiClient, instance_name, "client")
          else
            ui.warn("Corresponding node and client for the #{instance_name} server were not deleted and remain registered with the Chef Server")
          end
        end
      end
    end
  end
end
