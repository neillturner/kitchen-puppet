# encoding: utf-8
require 'simplecov'

# Filter out our tests from code coverage
SimpleCov.start do
  add_filter '/spec/'
end
