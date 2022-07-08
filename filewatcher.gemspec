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

  s.files = Dir[File.join('{lib,spec}', '**', '{*,.*}')]

  s.licenses = ['MIT']

  s.metadata = {
    'rubygems_mfa_required' => 'true'
  }

  s.required_ruby_version = '>= 2.6', '< 4'

  s.add_development_dependency 'bundler', '~> 2.0'
  s.add_development_dependency 'bundler-audit', '~> 0.9.0'

  s.add_development_dependency 'gem_toys', '~> 0.12.1'
  s.add_development_dependency 'toys', '~> 0.13.0'

  s.add_development_dependency 'codecov', '~> 0.6.0'
  s.add_development_dependency 'rspec', '~> 3.8'

  ## https://github.com/rubocop/rubocop/issues/10147
  s.add_development_dependency 'rubocop', '~> 1.31.2'
  s.add_development_dependency 'rubocop-performance', '~> 1.5'
  s.add_development_dependency 'rubocop-rspec', '~> 2.0'
end
