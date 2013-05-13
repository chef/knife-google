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

# Google compute engine, attached disk of an instance

require 'google/compute/mixins/utils'

module Google
  module Compute
    
    class AttachedDisk
      include Utils

      attr_reader :kind, :type, :mode, :source
      attr_reader :device_name, :index, :boot
      
      def initialize(data)
        @kind = data["kind"]
        @type = data["type"]
        @mode= data["mode"]
        @source = data["source"]
        @device_name = data["deviceName"] 
        @index = data["index"]
        @boot = data["boot"]
      end
    end
  end
end
