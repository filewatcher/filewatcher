# frozen_string_literal: true

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

  s.required_ruby_version = '>= 3.0', '< 5'

  s.add_dependency 'logger', '~> 1.7'
  s.add_dependency 'module_methods', '~> 0.1.0'
end
