#
# Author:: Chirag Jog (<chiragj@websym.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require 'open3'

class Chef
  class Knife
    module GoogleBase

     def validate_project(project_id)
        stdin, stdout, stderr = Open3.popen3("gcompute getproject --project_id=#{project_id}")
        stdin.puts("\n")
        error = stderr.read
        if not error.downcase.scan("error").empty?
          ui.error("#{error}")
          if not error.scan("Authentication has failed").empty?
            ui.error("If not authenticated, please Authenticate gcompute to access the Google Compute Cloud")
            ui.error("Authenticate by executing gcompute auth --project_id=<project_id>")
          end
          exit 1
        end 
      end
    end
  end
end
