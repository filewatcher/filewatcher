require 'rubygems'
require 'rake'
require 'rake/testtask'

task :default => :test
task :test do
  sh "bacon -Ilib -Itest --automatic --quiet"
end

# begin
#   require 'jeweler'
#   Jeweler::Tasks.new do |gem|
#     gem.name = "filewatcher"
#     gem.summary = %Q{Simple filewatcher.}
#     gem.description = %Q{Detect changes in filesystem.}
#     gem.email = "thomas.flemming@gmail.com"
#     gem.homepage = "http://github.com/thomasfl/filewatcher"
#     gem.executables = ["filewatcher"]
#     gem.authors = ["Thomas Flemming"]
#     gem.add_dependency 'trollop', '~> 2.0'
#     gem.licenses = ["MIT"]
#   end
# rescue LoadError
#   puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
# end

# task :test => :check_dependencies

# task :default => :test
