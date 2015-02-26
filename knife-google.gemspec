# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'knife-google/version'

Gem::Specification.new do |s|
  s.name = "knife-google"
  s.version = Knife::Google::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Chiraq Jog", "Ranjib Dey", "James Tucker", "Paul Rossman", "Eric Johnson"]
  s.license = "Apache-2.0"
  s.email = "paulrossman@google.com"
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.md", "LICENSE", "CONTRIB.md" ]
  s.summary = "Manage Google Compute Engine servers, disks, and zones"
  s.description = "Google Compute Engine Support for Chef's Knife Command"
  s.homepage = "http://docs.chef.io/"

  s.add_runtime_dependency 'chef', '~> 12.0.3'
  s.add_runtime_dependency 'extlib', '~> 0.9'
  s.add_runtime_dependency 'google-api-client' , '~> 0.8.2'
  s.add_runtime_dependency 'multi_json', '~> 1.10'
  s.add_runtime_dependency 'mixlib-config', '~> 2.0'
  s.files = `git ls-files`.split($/)
  #s.files = Dir['CONTRIB.md', 'Gemfile', 'LICENSE', 'README.md', 'Rakefile', 'knife-google.gemspec', 'lib/**/*', 'spec/**/*']

  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'rspec', '~> 3.1'
  s.add_development_dependency 'simplecov', '~> 0.9'
end
