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
require 'multi_json'
require 'google/compute/exception'

module Google
  module Compute
    module Utils

      def first_letter_lowercase_camelize(word)
        first, *rest = word.split('_')
        first + rest.map(&:capitalize).join
      end

      def to_hash
        hash={}
        instance_variables.each do |variable|
          variable_name =  first_letter_lowercase_camelize( variable.to_s.sub(/^@/,'') )
          next if variable_name == 'dispatcher'
          variable_value = instance_variable_get(variable)
          if variable_value.is_a?(String) 
            hash[variable_name] =   variable_value
          elsif variable_value.is_a?(Array)
            hash[variable_name] =   variable_value.collect{|v| 
                v.respond_to?(:to_hash) ? v.to_hash : v 
                }
          elsif variable_value.is_a?(Hash)
            hash[variable_name] =   Hash[variable_value.collect{ |k,v| 
                  [k, v.respond_to?(:to_hash) ? v.to_hash : v ]}
                ]
          elsif variable_value.is_a?(Time)
            hash[variable_name] =   variable_value.to_s
          elsif variable_value.respond_to?(:to_hash)
            hash[variable_name] =   variable_value.to_hash
          else
            hash[variable_name] =   variable_value.to_s
          end
        end
        hash
      end

      def to_json
        MultiJson.dump(to_hash)
      end
    end
  end
end
