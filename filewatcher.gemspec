# -*- encoding: utf-8 -*-
require File.dirname(__FILE__) + '/lib/filewatcher'
require 'date'

Gem::Specification.new do |s|
  s.name          = 'filewatcher'
  s.version       = FileWatcher::VERSION
  s.date          = Date.today.to_s

  s.authors       = ['Thomas Flemming']
  s.email         = ['thomas.flemming@gmail.com']
  s.homepage      = 'http://github.com/thomasfl/filewatcher'
  s.summary       = 'Lighweight filewatcher.'
  s.description   = 'Detect changes in filesystem. Works anywhere.'

  s.require_paths = ['lib']
  s.files = [
    'LICENSE',
    'README.md',
    'Rakefile',
    'bin/filewatcher',
    'lib/filewatcher.rb'
  ]
  s.executables   = ['filewatcher']
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")

  s.licenses = ['MIT']

  s.add_runtime_dependency     'trollop', '~> 2.1.2'
  s.add_development_dependency 'rake', '~> 12.0'
  s.add_development_dependency 'bacon', '~> 1.2'
end
