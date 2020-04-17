# frozen_string_literal: true

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)

  task default: :spec
rescue LoadError
  puts 'No RSpec available'
end
