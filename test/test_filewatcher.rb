require 'rubygems'
require 'bacon'
require 'fileutils'
require File.expand_path("../lib/filewatcher.rb",File.dirname(__FILE__))

describe FileWatcher do

  it "should detect file deletions" do
    filename = "test/fixtures/file1.txt"
    open(filename,"w") { |f| f.puts "content1" }
    filewatcher = FileWatcher.new(["test/fixtures"])
    filewatcher.filesystem_updated?.should.be.false
    FileUtils.rm(filename)
    filewatcher.filesystem_updated?.should.be.true
  end

  it "should detect file additions" do
    filename = "test/fixtures/file1.txt"
    FileUtils.rm(filename) if File.exists?(filename)
    filewatcher = FileWatcher.new(["test/fixtures"])
    filewatcher.filesystem_updated?.should.be.false
    open(filename,"w") { |f| f.puts "content1" }
    filewatcher.filesystem_updated?.should.be.true
  end

  it "should detect file updates" do
    filename = "test/fixtures/file1.txt"
    open(filename,"w") { |f| f.puts "content1" }
    filewatcher = FileWatcher.new(["test/fixtures"])
    filewatcher.filesystem_updated?.should.be.false
    sleep 1
    open(filename,"w") { |f| f.puts "content2" }
    filewatcher.filesystem_updated?.should.be.true
  end

  it "should detect new files in subfolders" do
    subfolder = 'test/fixtures/new_sub_folder'
    filewatcher = FileWatcher.new(["test/fixtures"])
    filewatcher.filesystem_updated?.should.be.false
    FileUtils::mkdir_p subfolder
    filewatcher.filesystem_updated?.should.be.false
    open(subfolder + "/file.txt","w") { |f| f.puts "xyz" }
    filewatcher.filesystem_updated?.should.be.true
    FileUtils.rm_rf subfolder
  end

end
