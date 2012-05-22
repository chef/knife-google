$:.unshift(File.dirname(__FILE__) + '/lib')
require 'knife-google/version'

Gem::Specification.new do |s|
  s.name = 'knife-google'
  s.version = KnifeGoogle::VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.rdoc", "LICENSE" ]
  s.summary = "Google Compute Cloud Support for Chef's Knife Command"
  s.description = s.summary
  s.author = "Chirag Jog"
  s.email = "chiragj@websym.com"
  s.homepage = "http://wiki.opscode.com/display/chef"

  s.add_dependency "chef", ">= 0.9.14"
  s.add_dependency "net-ssh", ">= 2.0.3"
  s.add_dependency "net-ssh-multi", ">= 1.0.1"
  s.add_dependency "net-scp", "~> 1.0.4"
  s.add_dependency "highline"
  s.add_dependency "json"
  s.require_path = 'lib'
  s.files = %w(LICENSE README.rdoc) + Dir.glob("lib/**/*")
end
