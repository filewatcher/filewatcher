# frozen_string_literal: true

require_relative 'lib/filewatcher'
require_relative 'lib/filewatcher/version'
require 'date'

Gem::Specification.new do |s|
  s.name          = 'filewatcher'
  s.version       = Filewatcher::VERSION
  s.date          = Date.today.to_s

  s.authors       = ['Thomas Flemming']
  s.email         = ['thomas.flemming@gmail.com']
  s.homepage      = 'http://github.com/thomasfl/filewatcher'
  s.summary       = 'Lighweight filewatcher.'
  s.description   = 'Detect changes in filesystem. Works anywhere.'

  s.files = Dir[File.join('{bin,lib}', '**', '{*,.*}')]
  s.executables   = ['filewatcher']
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")

  s.licenses = ['MIT']

  s.add_runtime_dependency     'optimist', '~> 3.0'

  s.add_development_dependency 'bacon', '~> 1.2'
  s.add_development_dependency 'bacon-custom_matchers_messages', '~> 0.1'
  s.add_development_dependency 'rake', '~> 12.0'
  s.add_development_dependency 'rubocop', '~> 0.57'
end
