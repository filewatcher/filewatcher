require 'rubygems'
require 'rake'
require 'rake/testtask'

task default: :test

desc 'Run tests'
task :test do
  sh 'bacon -Ilib -Itest --automatic --quiet'
  delete_list =
    %w(test/fixtures/file3.txt
       test/fixtures/file4.txt
       test/fixtures/file5.txt
       test/fixtures/file6.txt
       test/fixtures/file7.txt)
  delete_list.each do |file|
    FileUtils.rm(file)
  end
end
