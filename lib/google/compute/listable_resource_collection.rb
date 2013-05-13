# Copyright 2013 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless autoload :d by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'google/compute/resource_collection'

module Google
  module Compute
    class ListableResourceCollection < ResourceCollection

      def list(options={})
        data = @dispatcher.dispatch(:api_method => api_resource.list, :parameters=>options)
        items = []
        if data.has_key?("items")
          data["items"].each do |item|
            items << @resource_class.new(item.merge!(:dispatcher=>@dispatcher))
          end
        end
        items
      end
    end
  end
end
