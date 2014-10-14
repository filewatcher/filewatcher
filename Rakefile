require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "filewatcher"
    gem.summary = %Q{Simple filewatcher.}
    gem.description = %Q{Detect changes in filesystem.}
    gem.email = "thomas.flemming@gmail.com"
    gem.homepage = "http://github.com/thomasfl/filewatcher"
    gem.executables = ["filewatcher"]
    gem.authors = ["Thomas Flemming"]
    gem.add_dependency 'trollop', '~> 2.0'
    gem.licenses = ["MIT"]
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test
