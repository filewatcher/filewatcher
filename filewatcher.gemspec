# -*- encoding: utf-8 -*-
require File.dirname(__FILE__) + '/lib/filewatcher'
require 'date'

Gem::Specification.new do |s|
  s.name          = 'filewatcher'
  s.version       = FileWatcher.VERSION
  s.date          = Date.today.to_s

  s.authors       = ['Thomas Flemming']
  s.email         = ['thomas.flemming@gmail.com']
  s.homepage      = 'http://github.com/thomasfl/filewatcher'
  s.summary       = 'Lighweight filewatcher.'
  s.description   = 'Detect changes in filesystem.'

  s.require_paths = ['lib']
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = ['filewatcher']

  s.licenses = ['MIT']

  s.files = [
    'LICENSE',
    'README.md',
    'Rakefile',
    'bin/filewatcher',
    'lib/filewatcher.rb'
  ]

  s.add_runtime_dependency('trollop','~> 2.0')
  s.add_development_dependency('rake','~> 10.3')
  s.add_development_dependency('bacon','~> 1.2')
end
