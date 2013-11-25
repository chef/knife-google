# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'knife-google/version'

Gem::Specification.new do |s|
  s.name = 'knife-google'
  s.version = Knife::Google::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Chiraq Jog", "Ranjib Dey", "James Tucker", "Paul Rossman", "Eric Johnson"]
  s.email = "paulrossman@google.com"
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.md", "LICENSE", "CONTRIB.md" ]
  s.summary = "Manage Google Compute Engine servers, disks, and zones"
  s.description = "Google Compute Engine Support for Chef's Knife Command"
  s.homepage = "http://wiki.opscode.com/display/chef"

  s.add_dependency "chef", ">= 0.10.0"
  s.add_dependency "google-api-client"
  s.add_dependency "multi_json"
  s.add_dependency "mixlib-config"
  s.files = `git ls-files`.split($/)
  #s.files = Dir['CONTRIB.md', 'Gemfile', 'LICENSE', 'README.md', 'Rakefile', 'knife-google.gemspec', 'lib/**/*', 'spec/**/*']

  s.add_development_dependency "rspec"
  s.add_development_dependency "rake"
  s.add_development_dependency "simplecov"
end
