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
    class Firewall < Resource

      attr_reader :network, :source_ranges, :source_tags
      attr_reader :target_tags, :allowed
      
      def source_tags=(tags)
        raise ParameterValidation, " tags must be an array of words" unless tags.is_a?(Array)
        patch(:sourceTags=>tags)
        update!
      end

      def target_tags=(tags)
        raise ParameterValidation, " tags must be an array of words" unless tags.is_a?(Array)
        patch(:targetTags=>tags)
        update!
      end

      def source_ranges=(ranges)
        raise ParameterValidation, " source ranges must be an array of words" unless ranges.is_a?(Array)
        patch(:sourceRanges => ranges)
        update!
      end

      def allowed=(allowed)
        raise ParameterValidation, "allowed ingress rules must be an array of hashes" unless allowed.is_a?(Array)
        patch(:allowed => allowed)
        update!
      end

      def from_hash(data)
        super(data)
        @network = data["network"]
        @source_ranges = data["sourceRanges"]
        @source_tags = data["sourceTags"]
        @target_tags = data["targetTags"]
        @allowed = data["allowed"]
      end

      def patch(body_object)
        body_object[:name] = name unless body_object.has_key?(:name)
        body_object[:network] = network unless body_object.has_key?(:network)
        data = @dispatcher.dispatch(:api_method => api_resource.patch, 
                           :parameters=>{:firewall => name },
                           :body_object => body_object)
        GlobalOperation.new(data.merge!(:dispatcher=>@dispatcher))                                 
      end
    end
  end
end
