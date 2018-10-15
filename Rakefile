# encoding: UTF-8

require 'bundler/gem_tasks'
require 'rubocop/rake_task'
require 'rspec/core/rake_task'

task default: [:rubocop, :spec, 'integration:docker']

RuboCop::RakeTask.new

RSpec::Core::RakeTask.new(:spec) do |t|
  file_list = FileList['spec/**/*_spec.rb']
  file_list = file_list.exclude('spec/integration/**/*_spec.rb')
  t.pattern = file_list
end

namespace :integration do
  desc 'Run integration tests with docker'
  task :docker do
    sh %(cd spec/integration && \
         bundle exec 'kitchen verify -l debug')
  end
  task :clean do
    sh %(cd spec/integration && \
         bundle exec 'kitchen destroy')
  end
end
