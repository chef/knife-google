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

CLI_PREFIX='gcutil'
class Chef
  class Knife
    module GoogleBase
      @parser = Yajl::Parser.new
      @gcompute = nil
      @cygwin_path = nil

      def is_platform_windows?
        return RUBY_PLATFORM.scan('w32').size > 0
      end

      def is_cygwin_installed?
          ENV['CYGWINPATH'] != nil
      end

      def gcompute
        return if @gcompute
        if is_platform_windows?
          if is_cygwin_installed?
	        #Remove extra quotes
	        @cygwin_path = ENV['CYGWINPATH'].chomp('\'').reverse.chomp('\'').reverse
            #FIXME Generalize the python binary 
            @gcompute="#{@cygwin_path}\\bin\\python2.6.exe #{@cygwin_path}\\bin\\#{CLI_PREFIX}"
	      else
            puts "Cannot Find Cygwin Installation !!! Please set CYGWINPATH to point to the Cygwin installation"
            exit 1
          end
        else
          Chef::Log.debug("Linux Environment")
          @gcompute = CLI_PREFIX
        end
      end

      def parser
        if @parser.nil?
          @parser = Yajl::Parser.new
        end
      end
      
      def to_json(data)
        data_s = StringIO::new(data.strip)
        parser.parse(data_s) {|obj| return obj}
      end

      def exec_shell_cmd(cmd)
        if is_platform_windows? and is_cygwin_installed?
          #Change the HOME PATH From Windows to Cygwin
          cygwin_home = "#{@cygwin_path}\\home\\#{ENV['USER']}"
  
          #Auth token should exist in either ENV['HOME'] or cygwin_home
          #XXX Find a way to remove the hard-coded file name
	  if not File.file?("#{ENV['HOME']}\\.#{CLI_PREFIX}_auth")
            ENV['HOME'] = cygwin_home
	  end
        end
        shell_cmd = Mixlib::ShellOut.new(cmd)
        shell_cmd.run_command
      end

      def validate_project(project_id)
        cmd = "#{gcompute} getproject --project_id=#{project_id}"
        Chef::Log.debug 'Executing ' + cmd
        getprj = exec_shell_cmd(cmd)
        if getprj.status.exitstatus > 0
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
