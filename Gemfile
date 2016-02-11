# encoding: UTF-8
source 'https://rubygems.org'
gemspec

gem 'rubocop', '~> 0.34'
gem 'rake', '~> 10.4.2'
gem 'rspec', '~> 3.3.0'
gem 'simplecov', '~> 0.10'
gem 'net-ssh', '~> 2.0'

group :integration do
  gem 'test-kitchen'
  # Until the fix for older ruby versions
  # is released to rubygems - get it from master
  gem 'kitchen-docker', github: 'portertech/kitchen-docker'
end
