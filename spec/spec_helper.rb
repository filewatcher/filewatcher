# frozen_string_literal: true

require 'simplecov'

if ENV['CI']
  require 'simplecov-cobertura'
  SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
end

SimpleCov.start

require_relative '../lib/filewatcher/spec_helper'

RSpec.configure do |config|
  config.example_status_persistence_file_path = "#{__dir__}/examples.txt"
end

## For case when required from dumpers
if Object.const_defined?(:RSpec)
  RSpec::Matchers.define :include_all_files do |expected|
    match do |actual|
      expected.all? { |file| actual.include? File.expand_path(file) }
    end
  end
end
