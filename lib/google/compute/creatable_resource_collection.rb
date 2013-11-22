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

module Google
  module Compute
    class CreatableResourceCollection < DeletableResourceCollection

      def create(options={})
        if ["Server"].include? self.resource_class_name
          data = @dispatcher.dispatch(:api_method => api_resource.insert, 
                           :parameters=>{:project=>project, :zone=>options[:zone]},
                           :body_object => options )
          ZoneOperation.new(data.merge!(:dispatcher=>@dispatcher))
        elsif ["Disk"].include? self.resource_class_name
          data = @dispatcher.dispatch(:api_method => api_resource.insert,
                           :parameters=>{:project=>project, :zone=>options[:zone], :sourceImage=>options[:sourceImage]},
                           :body_object => options )
          ZoneOperation.new(data.merge!(:dispatcher=>@dispatcher))
        else
          data = @dispatcher.dispatch(:api_method => api_resource.insert, 
                           :parameters=>{:project=>project},
                           :body_object => options )
          GlobalOperation.new(data.merge!(:dispatcher=>@dispatcher))
        end
      end

      def insert(options={})
        create(options)
      end

      def create_snapshot(options={})
        data = @dispatcher.dispatch(:api_method => api_resource.create_snapshot, :parameters=>options)
        ZoneOperation.new(data.merge!(:dispatcher=>@dispatcher)) unless data.nil?
      end

    end
  end
end
