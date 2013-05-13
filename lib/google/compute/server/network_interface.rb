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

require 'google/compute/server/network_interface/access_config'
require 'google/compute/mixins/utils'

module Google
  module Compute
    class NetworkInterface
      include Utils

      attr_reader :name, :network, :network_ip, :access_configs
      
      def initialize(data)
        @name = data["name"]
        @network = data["network"]
        @network_ip = data["networkIP"]
        @access_configs=[]
        if data["accessConfigs"] && data["accessConfigs"].is_a?(Array)
          data["accessConfigs"].each do |config|
            @access_configs << AccessConfig.new(config)
          end
        end
      end
    end
  end
end
