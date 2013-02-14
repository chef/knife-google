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

require 'rubygems'
require 'rubygems/package_task'
require 'mixlib/shellout'

GEM_NAME = "knife-google"
GCOMPUTE_VERSION="1.7.1"
GCOMPUTE_PACKAGE="gcutil-#{GCOMPUTE_VERSION}"
GCOMPUTE_PACKAGE_LOCATION="external"
GCOMPUTE_DEST_DIR="/usr/local/share"

spec = eval(File.read("knife-google.gemspec"))

Gem::PackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

begin
  require 'sdoc'

  Rake::RDocTask.new do |rdoc|
    rdoc.title = "Chef Ruby API Documentation"
    rdoc.main = "README.rdoc"
    rdoc.options << '--fmt' << 'shtml' # explictly set shtml generator
    rdoc.template = 'direct' # lighter template
    rdoc.rdoc_files.include("README.rdoc", "LICENSE", "lib/**/*.rb")
    rdoc.rdoc_dir = "rdoc"
  end
rescue LoadError
  puts "sdoc is not available. (sudo) gem install sdoc to generate rdoc documentation."
end


task :install => :package do

  def is_platform_windows?
    return RUBY_PLATFORM.scan('w32').size > 0
  end

  def is_cygwin_installed?
    ENV['CYGWINPATH'] != nil and ENV['PATH'].scan('cygwin').size > 0
  end

  if is_platform_windows?
    if is_cygwin_installed?
      cygwin_path = ENV['CYGWINPATH'].chomp('\'').reverse.chomp('\'').reverse
      cmd = "tar -xf #{GCOMPUTE_PACKAGE_LOCATION}\\#{GCOMPUTE_PACKAGE}.tar.gz -C #{cygwin_path}\\bin\\ &" +
      "#{cygwin_path}\\bin\\ln.exe -sf /bin/#{GCOMPUTE_PACKAGE}/gcutil /bin/gcutil"
    else
      puts "Cannot Find Cygwin Installation !!! Please set environment variables CYGWINPATH to point the Cygwin Installation"
      exit 1
    end
  else #Platform is Linux/OSX
    cmd = "sudo tar -xf #{GCOMPUTE_PACKAGE_LOCATION}/#{GCOMPUTE_PACKAGE}.tar.gz -C #{GCOMPUTE_DEST_DIR};" +
    "sudo ln -sf #{GCOMPUTE_DEST_DIR}/#{GCOMPUTE_PACKAGE}/gcutil  /usr/local/bin/gcutil"
  end

  #Install the gcompute library on which the knife plugin depends on
  shell_cmd = Mixlib::ShellOut.new(cmd)
  shell_cmd.run_command
  puts shell_cmd.stdout
  err = shell_cmd.stderr
  if err.size > 0
    STDERR.puts "Failed to install gcompute. Error: #{err}"
    #Continue Anyways
  end

  sh %{gem install pkg/#{GEM_NAME}-#{KnifeGoogle::VERSION} --no-rdoc --no-ri}
end

task :uninstall do
  sh %{gem uninstall #{GEM_NAME} -x -v #{KnifeGoogle::VERSION} }
end

begin
  require 'rspec/core/rake_task'

  task :default => :spec

  desc "Run all specs in spec directory"
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = 'spec/unit/**/*_spec.rb'
  end

rescue LoadError
  STDERR.puts "\n*** RSpec not available. (sudo) gem install rspec to run unit tests. ***\n\n"
end
