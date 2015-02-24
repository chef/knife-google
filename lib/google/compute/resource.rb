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

require 'extlib'
require 'google/compute/exception'
require 'google/compute/mixins/utils'
require 'multi_json'

module Google
  module Compute
    class Resource
      include Utils

      attr_reader :kind, :id, :creation_timestamp
      attr_reader :name, :description, :self_link, :dispatcher

      def initialize(resource_data)
        from_hash(resource_data)
      end

      def to_s
        name
      end

      def project
        if self.is_a?(Google::Compute::Project)
          name
        else
          self_link=~Regexp.new('/projects/(.*?)/')
          $1
        end
      end  

      def api_resource
        # MacineType => machine_types
        # Servers => instances
        collection_name = self.class.name.split('::').last.snake_case + "s"
        if collection_name == "servers"
          @dispatcher.compute.send("instances")
        else
          @dispatcher.compute.send(collection_name)
        end
      end

      def type
        kind.split('#').last
      end

      def self.class_name
        name.split('::').last.downcase
      end

      def update!
        data= @dispatcher.dispatch(:api_method=>api_resource.get,:parameters=>{type =>name})
        from_hash(data.merge(:dispatcher => @dispatcher))
      end
      
      def from_hash(resource_data)
        @kind = resource_data["kind"]
        @name = resource_data["name"]
        @self_link = resource_data["selfLink"]
        @id = resource_data["id"].to_i
        @description = resource_data["description"]
        unless resource_data["creationTimestamp"].nil?
          @creation_timestamp = Time.parse(resource_data["creationTimestamp"])
        end
        @dispatcher = resource_data[:dispatcher]
      end
    end
  end
end
