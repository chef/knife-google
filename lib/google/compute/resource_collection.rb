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
    class ResourceCollection

      attr_reader :dispatcher

      def initialize(options)
        @dispatcher = options[:dispatcher]
        @resource_class= options[:resource_class]
      end

      def get(options={})
        if options.is_a?(String)
          options = name_to_hash(options)
        elsif options.is_a?(Google::Compute::Resource)
          options = name_to_hash(options.name)
        elsif options.is_a?(Hash)  && options.has_key?(:name)
          options.merge!(name_to_hash(options[:name]))
          options.delete(:name)
        elsif options.is_a?(Hash) && options.has_key?(@resource_class.class_name.to_sym)
        else
          raise ParameterValidation, "argument must be :" +
                "name of the resource, or "+
                "a resource object, or " +
                "a hash with a key as resource name, eg ({:disk=>'xxx'}) , or " +
                "a hash with a :name key " + 
                "you have passed '#{options.inspect}'"
        end
        if options.is_a?(Hash) && options.has_key?("server")
          options[:instance] = options["server"]
          options.delete("server")
        end
        data = @dispatcher.dispatch(:api_method=>api_resource.get, :parameters=>options)
        @resource_class.new(data.merge(:dispatcher=>@dispatcher))
      end

      def name_to_hash(resource_name)
        {downcase_first_letter(resource_class_name) => resource_name}
      end

      def downcase_first_letter(word)
        word.sub(/^[A-Z]/) {|f| f.downcase}
      end

      def resource_class_name
        name = @resource_class.name.split('::').last
      end

      def project
        @dispatcher.project
      end

      def api_resource
        # Servers => instances
        collection_name = resource_class_name.snake_case + "s"
        if collection_name == "servers"
          @dispatcher.compute.send("instances")
        else
          @dispatcher.compute.send(collection_name)
        end
      end
    end
  end
end
