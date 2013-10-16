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

module Google
  module Compute
    class Project < Resource

      attr_reader :common_instance_metadata, :quotas

      def from_hash(data)
        super(data)
        @common_instance_metadata = data["commonInstanceMetadata"]
        @quotas = data["quotas"]
      end

      def set_common_instance_metadata(metadata)
        data = @dispatcher.dispatch(:api_method=>api_resource.set_common_instance_metadata,
                    :parameters=>{:project=>name},
                    :body_object=>{
                        "kind" => "compute#metadata",
                        "items" => metadata
                        }
                   )
        update!
      end

      def add_common_instance_metadata!(options)
        temp_metadata = @common_instance_metadata["items"]
        options.keys.each do |k|
          if common_instance_metadata["items"].any?{|metadata| metadata["key"] == k}
            raise ParameterValidation, "Key:'#{k}' already exist in common server metadata"
          else
            temp_metadata << {'key'=>k ,'value'=> options[k]} 
          end
        end
        set_common_instance_metadata(temp_metadata)
      end

      def remove_common_instance_metadata!(options)
        temp_metadata = common_instance_metadata["items"]
        options.keys.each do |k|
          unless common_instance_metadata["items"].any?{|metadata| metadata['key'] == k}
            raise ParameterValidation, "Key:'#{k}' does not exist in common server metadata"
          else
            temp_metadata.delete({'key'=>k, 'value'=> options[k]}) 
          end
        end
        set_common_instance_metadata(temp_metadata)
      end

      def update_common_instance_metadata!(options)
        temp_metadata = @common_instance_metadata["items"]
        options.keys.each do |k|
          if common_instance_metadata["items"].any?{|metadata| metadata["key"] == k}
            metadata = common_instance_metadata["items"].select{|metadata| metadata["key"] == k}.first
            temp_metadata.delete(metadata) 
          end
          temp_metadata << { 'key' => k, 'value'=> options[k]}
        end
        set_common_instance_metadata(temp_metadata)
      end

    end
  end
end
