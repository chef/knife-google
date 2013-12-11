# Copyright 2013 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'google/compute/server/serial_port_output'
require 'google/compute/server/network_interface'
require 'google/compute/server/attached_disk'

module Google
  module Compute
    class Server < Resource

      attr_reader  :tags, :machine_type, :status, :status_message, :zone
      attr_reader  :network_interfaces, :disks, :metadata, :service_accounts
      attr_reader  :scheduling

      def from_hash(data)
        super(data)
        @tags = data["tags"]
        @machine_type = data["machineType"]
        @status = data["status"]
        @status_message = data["statusMessage"]
        @zone = data["zone"]
        @network_interfaces = []
        if data["networkInterfaces"] || data["networkInterfaces"].is_a?(Array)
          data["networkInterfaces"].each do |interface|
            @network_interfaces <<  NetworkInterface.new(interface)
          end
        end  
        @disks = []
        if data["disks"] || data["disks"].is_a?(Array)
          data["disks"].each do |disk_data|
            @disks <<  AttachedDisk.new(disk_data)
          end
        end  
        @metadata = data["metadata"]
        @service_accounts = data["service_accounts"]
        @scheduling = data["scheduling"]
      end

      def serial_port_output
        @serial_port_output ||= begin
          data = @dispatcher.dispatch(:api_method => api_resource.get_serial_port_output, 
                             :parameters=>{ :project =>project, :zone=>zone,
                                            :instance => name
                                          })
          SerialPortOutput.new(data)                                 
        end
      end

      def add_access_config(options={})
        interface = options.delete(:network_interface) 
        interface = interface.name if interface.is_a?(Network::Interface)
        body_object = options[:access_config].to_hash 
        data = @dispatcher.dispatch(:api_method => api_resource.add_access_config, 
                           :parameters=>{ :project => project,
                                          :instance => name,
                                          :network_interface => interface
                                        },
                          :body_object => body_object)
        ZoneOperation.new(data.merge!(:dispatcher=>@dispatcher))
      end

      def delete_access_config(options={})
        interface = options.delete(:network_interface) 
        interface = interface.name if interface.is_a?(Network::Interface)
        access_config = options[:access_config].to_hash if  options[:access_config].is_a?(AccessConfig)
        data = @dispatcher.dispatch(:api_method => api_resource.delete_access_config, 
                           :parameters=>{ :project =>project,
                                          :instance => name,
                                          :network_interface => interface,
                                          :access_config => access_configs
                                        })
        ZoneOperation.new(data.merge!(:dispatcher=>@dispatcher))
      end
    end
  end
end
