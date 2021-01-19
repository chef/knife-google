$:.push File.expand_path("../lib", __FILE__)
require "knife-google/version"

Gem::Specification.new do |s|
  s.name = "knife-google"
  s.version = Knife::Google::VERSION
  s.authors = ["Chiraq Jog", "Ranjib Dey", "James Tucker", "Paul Rossman", "Eric Johnson", "Chef Partner Engineering"]
  s.license = "Apache-2.0"
  s.email = ["paulrossman@google.com", "partnereng@chef.io"]
  s.summary = "Google Compute Engine Support for Chef's Knife Command"
  s.description = s.summary
  s.homepage = "https://github.com/chef/knife-google"
  s.files         = %w{LICENSE} + Dir.glob("lib/**/*")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]
  s.required_ruby_version = ">= 2.6"

  s.add_dependency "chef",              ">= 15.11"
  s.add_dependency "knife-cloud",       ">= 4.0.0"
  s.add_dependency "google-api-client", ">= 0.23.9", "< 0.54.0" # each version introduces breaking changes which we need to validate
  s.add_dependency "gcewinpass",        "~> 1.1"
end
