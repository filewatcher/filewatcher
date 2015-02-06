require 'rubygems'
require 'rake'
require 'rake/testtask'

task :default => :test

desc "Run tests"
task :test do
  sh "bacon -Ilib -Itest --automatic --quiet"
end
