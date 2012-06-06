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

require 'stringio'
require 'yajl'
require 'mixlib/shellout'

class Chef
  class Knife
    module GoogleBase

      @parser = Yajl::Parser.new

      def parser
        if @parser.nil?
          @parser = Yajl::Parser.new
        end
      end
      
      def to_json(data)
        data_s = StringIO::new(data)
        parser.parse(data_s)
      end

      def exec_shell_cmd(cmd)
        shell_cmd = Mixlib::ShellOut.new(cmd)
        shell_cmd.run_command
      end

      def validate_project(project_id)
        getprj = exec_shell_cmd("gcompute getproject --project_id=#{project_id}")
        if getprj.status.to_i > 0
          if not getprj.stdout.scan("Enter verification code").empty?
            ui.error("If not authenticated, please Authenticate gcompute to access the Google Compute Cloud")
            ui.error("Authenticate by executing gcompute auth --project_id=<project_id>")
            exit 1
          end
          ui.error("#{getprj.stderr}")
          exit 1
        end
      end
    end
  end
end
