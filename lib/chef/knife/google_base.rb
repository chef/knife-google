# Copyright 2013 Google Inc. All Rights Reserved.
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

require 'chef/knife'
require 'google/compute'

class Chef
  class Knife
    module GoogleBase

      # hack for mixlib-cli workaround
      # https://github.com/opscode/knife-ec2/blob/master/lib/chef/knife/ec2_base.rb
      def self.included(includer)
        includer.class_eval do
          deps do
            require 'google/compute'
            require 'chef/json_compat'
          end

          option :compute_credential_file,
            :short => "-f CREDENTIAL_FILE",
            :long => "--gce-credential-file CREDENTIAL_FILE",
            :description => "Google Compute credential file (google setup can create this)"
        end
      end

      def client
        @client ||= begin
          Google::Compute::Client.from_json(config[:compute_credential_file])
        end
      end

      def selflink2name(selflink)
        selflink.to_s == '' ? selflink.to_s : selflink.split('/').last
      end

      def msg_pair(label, value, color=:cyan)
        if value && !value.to_s.empty?
          ui.info("#{ui.color(label, color)}: #{value}")
        end
      end

      def disks(instance)
        instance.disks.collect{|d|d.device_name}.compact
      end

      def private_ips(instance)
        instance.network_interfaces.collect{|ni|ni.network_ip}.compact
      end

      def public_ips(instance)
        instance.network_interfaces.collect{|ni|
          ni.access_configs.map{|ac|
            ac.nat_ip
          }
        }.flatten.compact
      end

      def locate_config_value(key)
        key = key.to_sym
        config[key] || Chef::Config[:knife][key]
      end
    end
  end
end
