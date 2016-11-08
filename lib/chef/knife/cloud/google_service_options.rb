# frozen_string_literal: true
#
# Author:: Chef Partner Engineering (<partnereng@chef.io>)
# Copyright:: Copyright (c) 2016 Chef Software, Inc.
# License:: Apache License, Version 2.0
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
#

class Chef::Knife::Cloud
  module GoogleServiceOptions
    def self.included(includer)
      includer.class_eval do
        option :gce_project,
          long:        "--gce-project PROJECT",
          description: "Name of the Google Cloud project to use"

        option :gce_zone,
          short:       "-Z ZONE",
          long:        "--gce-zone ZONE",
          description: "Name of the Google Compute Engine zone to use"

        option :gce_max_pages,
          long:        "--gce-max-pages NUMPAGES",
          description: "Maximum number of pages to request for paginated listing requests, defaults to 20",
          default:     20,
          proc:        proc { |pages| pages.to_i }

        option :gce_max_page_size,
          long:        "--gce-max-page-size NUMPAGES",
          description: "Maximum number of items per page to request for paginated listing requests, defaults to 100",
          default:     100,
          proc:        proc { |items| items.to_i }

        option :request_refresh_rate,
          long:        "--request-refresh-rate SECS",
          description: "Number of seconds to sleep between each check of the request status, defaults to 2",
          default:     2,
          proc:        proc { |secs| secs.to_i }

        option :request_timeout,
          long:        "--request-timeout SECS",
          description: "Number of seconds to wait for a request to complete, defaults to 600",
          default:     600,
          proc:        proc { |secs| secs.to_i }
      end
    end
  end
end
