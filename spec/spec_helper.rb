# Copyright 2013 Google Inc. All Rights Reserved.
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

require 'simplecov'
SimpleCov.start do
  add_filter "/spec/"
  add_filter "/.bundle/"
  add_filter "/pkg/"
  add_filter "/pkg/"
end

require 'google/compute'

require 'support/resource_examples'
require 'support/mocks'

require 'chef'
require 'chef/knife/google_instance_create'
require 'chef/knife/google_instance_delete'
require 'chef/knife/google_instance_list'
require 'chef/knife/google_disk_list'
require 'chef/knife/google_disk_create'
require 'chef/knife/google_disk_delete'
require 'chef/knife/google_zone_list'
require 'chef/knife/google_setup'

require 'support/spec_google_base'

RSpec.configure do |config|
  config.include SpecData
  config.include Mocks
end
