# Copyright 2013 Google Inc. All Rights Reserved.
#
# Copyright 2013 Google Inc.
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
  end
end

require 'google/compute/version'
require 'google/compute/config'
require 'google/compute/resource_collection'
require 'google/compute/listable_resource_collection'
require 'google/compute/deletable_resource_collection'
require 'google/compute/creatable_resource_collection'
require 'google/compute/resource'
require 'google/compute/client'
require 'google/compute/exception'
require 'google/compute/disk'
require 'google/compute/firewall'
require 'google/compute/image'
require 'google/compute/server'
require 'google/compute/machine_type'
require 'google/compute/network'
require 'google/compute/project'
require 'google/compute/snapshot'
require 'google/compute/region'
require 'google/compute/zone'
require 'google/compute/global_operation'
require 'google/compute/region_operation'
require 'google/compute/zone_operation'
require 'google/compute/server/attached_disk'
require 'google/compute/server/network_interface'
require 'google/compute/server/serial_port_output'
require 'google/compute/server/network_interface/access_config'
