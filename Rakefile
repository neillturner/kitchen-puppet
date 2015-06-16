# encoding: UTF-8

require 'rubocop/rake_task'
require 'rspec/core/rake_task'

task default: [:rubocop, :spec]

RuboCop::RakeTask.new

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/**/*_spec.rb'
end
