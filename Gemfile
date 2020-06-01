source "https://rubygems.org"

gemspec

gem "knife-cloud", path: "../knife-cloud"

group :docs do
  gem "yard"
  gem "redcarpet"
  gem "github-markup"
end

group :test do
  gem "chefstyle"
  gem "rspec", "~> 3.1"
  gem "rake"
  if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.6")
    gem "chef-zero", "~> 14"
    gem "chef", "~> 15"
  else
    gem "chef"
  end
end

group :development do
  gem "pry"
  gem "pry-byebug"
  gem "pry-stack_explorer"
  gem "rb-readline"
  gem "simplecov", "~> 0.9"
end
