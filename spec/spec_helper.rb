# frozen_string_literal: true

require_relative '../lib/filewatcher/spec_helper'

require_relative 'spec_helper/ruby_watch_run'

## For case when required from dumpers
if Object.const_defined?(:RSpec)
  RSpec::Matchers.define :include_all_files do |expected|
    match do |actual|
      expected.all? { |file| actual.include? File.expand_path(file) }
    end
  end
end
