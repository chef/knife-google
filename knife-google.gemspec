# -*- encoding: utf-8 -*-
# frozen_string_literal: true
$:.push File.expand_path("../lib", __FILE__)
require "knife-google/version"

Gem::Specification.new do |s|
  s.name = "knife-google"
  s.version = Knife::Google::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Chiraq Jog", "Ranjib Dey", "James Tucker", "Paul Rossman", "Eric Johnson", "Chef Partner Engineering"]
  s.license = "Apache-2.0"
  s.email = ["paulrossman@google.com", "partnereng@chef.io"]
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.md", "LICENSE"]
  s.summary = "Google Compute Engine Support for Chef's Knife Command"
  s.description = s.summary
  s.homepage = "https://github.com/chef/knife-google"
  s.required_ruby_version = ">= 2.2.2"

  s.add_dependency "chef",              ">= 12.0"
  s.add_dependency "knife-cloud",       "~> 1.2.0"
  s.add_dependency "google-api-client", "~> 0.9.0"
  s.add_dependency "gcewinpass",        "~> 1.0"

  s.add_development_dependency "github_changelog_generator"

  s.files = `git ls-files -z`.split("\x0")
end
