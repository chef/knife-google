source "https://rubygems.org"

gemspec

group :docs do
  gem "yard"
  gem "redcarpet"
  gem "github-markup"
end

group :test do
  gem "chefstyle"
  gem "rspec", "~> 3.1"
  gem "rake"
  if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.7")
    gem "chef-zero", "~> 15"
    gem "chef", "~> 16"
  else
    gem "chef", "~> 16"
  end
end

group :development do
  gem "pry"
  gem "pry-byebug"
  gem "pry-stack_explorer"
  gem "rb-readline"
end
