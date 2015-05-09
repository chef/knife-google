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

require 'google/api_client'

class Chef
  class Knife
    module GoogleBase

      def self.included(includer)
        includer.class_eval do
          deps do
            require 'chef/knife'
            require 'knife-google/version'
            require 'multi_json'
          end

          option :gce_project,
            :long => "--gce-project PROJECT",
            :description => "Your Google project",
            :proc => Proc.new { |key| Chef::Config[:knife][:gce_project] = key }

        end
      end

      def client
        @client ||= begin
          client = Google::APIClient.new(
            :application_name => "knife-google-native-api-alpha",
            :application_version => ::Knife::Google::VERSION
          )
        end
      end

      def compute
        client.authorization = :google_app_default
        client.authorization.fetch_access_token!
        @compute ||= begin
          compute = client.discovered_api('compute')
        end
      end

      def selflink2name(selflink)
        selflink.to_s == '' ? selflink.to_s : selflink.split('/').last
      end

      def locate_config_value(key)
        key = key.to_sym
        config[key] || Chef::Config[:knife][key]
      end

      def msg_pair(label, value, color=:cyan)
        if value && !value.to_s.empty?
          ui.info("#{ui.color(label, color)}: #{value}")
        end
      end

    end
  end
end
