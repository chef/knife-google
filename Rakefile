# Copyright 2013, Google, Inc.
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
# encoding: utf-8

require 'rubygems'
require 'rake'
GEM_NAME = "knife-google"

spec = eval(File.read(GEM_NAME+".gemspec"))

require 'rubygems/package_task'

Gem::PackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

task :default => :spec

task :install => :package do
  sh %{gem install pkg/#{GEM_NAME}-#{Knife::Google::VERSION} --no-rdoc --no-ri}
end 

task :uninstall do
  sh %{gem uninstall #{GEM_NAME} -x -v #{Knife::Google::VERSION} }
end

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "#{GEM_NAME} #{version}"
  rdoc.rdoc_files.include('README*', 'LICENSE', 'CONTRIB*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
