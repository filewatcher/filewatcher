# frozen_string_literal: true

require_relative 'lib/filewatcher'
require_relative 'lib/filewatcher/version'

Gem::Specification.new do |s|
  s.name          = 'filewatcher'
  s.version       = Filewatcher::VERSION

  s.authors       = ['Thomas Flemming', 'Alexander Popov']
  s.email         = ['thomas.flemming@gmail.com', 'alex.wayfer@gmail.com']
  s.homepage      = 'http://github.com/filewatcher/filewatcher'
  s.summary       = 'Lightweight filewatcher.'
  s.description   = 'Detect changes in file system. Works anywhere.'

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
