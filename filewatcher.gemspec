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

  s.required_ruby_version = '~> 2.4'

  s.add_runtime_dependency 'optimist', '~> 3.0'

  s.add_development_dependency 'bundler', '~> 2.0'
  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'rspec', '~> 3.8'
  s.add_development_dependency 'rubocop', '~> 0.88.0'
  s.add_development_dependency 'rubocop-performance', '~> 1.5'
  s.add_development_dependency 'rubocop-rspec', '~> 1.38'
end
