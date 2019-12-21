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

  # make sure we can still test on Ruby 2.4
  if RUBY_VERSION.match?(/2\.4/)
    gem "chef", "~> 14"
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
