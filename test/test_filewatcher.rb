require 'rubygems'
require 'bacon'
require 'fileutils'
require File.expand_path("../lib/filewatcher.rb",File.dirname(__FILE__))



describe FileWatcher do

  fixtures =
    %w(test/fixtures/file4.rb
       test/fixtures/subdir/file6.rb
       test/fixtures/subdir/file5.rb
       test/fixtures/file2.txt
       test/fixtures/file1.txt
       test/fixtures/file3.rb)

  explicit_relative_fixtures =  fixtures.map { |it| "./#{it}" }

  subfolder = 'test/fixtures/new_sub_folder'

  after do
    FileUtils.rm_rf subfolder
  end

  def includes_all(elements)
    lambda { |it| elements.all? { |element| it.include? element }}
  end

  it "should handle absolute paths with globs" do
    filewatcher = FileWatcher.new(File.expand_path('test/fixtures/**/*'))

    filewatcher.filenames.should.satisfy &includes_all(fixtures.map { |it| File.expand_path(it) })
  end

  it "should handle globs" do
    filewatcher = FileWatcher.new('test/fixtures/**/*')

    filewatcher.filenames.should.satisfy &includes_all(fixtures)
  end


  it "should handle explicit relative paths with globs" do
    filewatcher = FileWatcher.new('./test/fixtures/**/*')

    filewatcher.filenames.should.satisfy &includes_all(explicit_relative_fixtures)
  end

  it "should handle explicit relative paths" do
    filewatcher = FileWatcher.new('./test/fixtures')

    filewatcher.filenames.should.satisfy &includes_all(explicit_relative_fixtures)
  end

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
    FileUtils::mkdir_p subfolder

    filewatcher = FileWatcher.new(["./test/fixtures"])
    filewatcher.filesystem_updated?.should.be.false

    open(subfolder + "/file.txt","w") { |f| f.puts "xyz" }
    filewatcher.filesystem_updated?.should.be.true
  end

  it "should detect new subfolders" do
    filewatcher = FileWatcher.new(["test/fixtures"])
    filewatcher.filesystem_updated?.should.be.false

    FileUtils::mkdir_p subfolder
    filewatcher.filesystem_updated?.should.be.true
  end

  it "should be stoppable" do
    filewatcher = FileWatcher.new(["test/fixtures"])
    thread = Thread.new(filewatcher){filewatcher.watch(0.1)}
    sleep 0.2  # thread needs a chance to start
    filewatcher.stop
    thread.join.should.equal thread # Proves thread successfully joined
  end

  it "should be pauseable/resumable" do
    filewatcher = FileWatcher.new(["test/fixtures"])
    filewatcher.filesystem_updated?.should.be.false
    processed = []
    thread = Thread.new(filewatcher,processed) do
      filewatcher.watch(0.1){|f,e| processed << f }
    end
    sleep 0.2  # thread needs a chance to start
    filewatcher.pause
    (1..4).each do |n|
      open("test/fixtures/file#{n}.txt","w") { |f| f.puts "content#{n}" }
    end
    sleep 0.2 # Give filewatcher time to respond
    processed.should.equal []  #update block should not have been called
    filewatcher.resume
    sleep 0.2 # Give filewatcher time to respond
    processed.should.equal []  #update block still should not have been called
    added_files = []
    (5..7).each do |n|
      added_files << "test/fixtures/file#{n}.txt"
      open(added_files.last,"w") { |f| f.puts "content#{n}" }
    end
    sleep 0.2 # Give filewatcher time to respond
    filewatcher.stop
    processed.should.satisfy &includes_all(added_files)
  end

  it "should process all remaining changes at finalize" do
    filewatcher = FileWatcher.new(["test/fixtures"])
    filewatcher.filesystem_updated?.should.be.false
    processed = []
    thread = Thread.new(filewatcher,processed) do
      filewatcher.watch(0.1){|f,e| processed << f }
    end
    sleep 0.2  # thread needs a chance to start
    filewatcher.stop
    thread.join
    added_files = []
    (1..4).each do |n|
      added_files << "test/fixtures/file#{n}.txt"
      open(added_files.last,"w") { |f| f.puts "content#{n}" }
    end
    filewatcher.finalize
    puts "What is wrong with finalize:"
    puts "Expect: #{added_files.inspect}"
    puts "Actual: #{processed.inspect}"
    processed.should.satisfy &includes_all(added_files)
  end

end
