require 'rubygems'
require 'bacon'
require 'fileutils'
require File.expand_path('../lib/filewatcher.rb', File.dirname(__FILE__))

describe FileWatcher do
  fixtures =
    %w(test/fixtures/file4.rb
       test/fixtures/subdir/file6.rb
       test/fixtures/subdir/file5.rb
       test/fixtures/file2.txt
       test/fixtures/file1.txt
       test/fixtures/file3.rb)

  explicit_relative_fixtures = fixtures.map { |it| "./#{it}" }

  subfolder = 'test/fixtures/new_sub_folder'

  after do
    FileUtils.rm_rf subfolder

    %w[
      test/fixtures/file3.txt
      test/fixtures/file4.txt
      test/fixtures/file5.txt
      test/fixtures/file6.txt
      test/fixtures/file7.txt
    ].each do |file|
      FileUtils.rm file, force: true
    end
  end

  def includes_all(elements)
    ->(it) { elements.all? { |element| it.include? element } }
  end

  it 'should exclude selected file patterns' do
    filewatcher = FileWatcher.new(
      File.expand_path('test/fixtures/**/*'),
      exclude: [File.expand_path('test/fixtures/**/*.txt')]
    )
    filtered_fixtures =
      %w(test/fixtures/file4.rb
         test/fixtures/subdir/file6.rb
         test/fixtures/subdir/file5.rb
         test/fixtures/file3.rb)
    filewatcher.filenames.should.satisfy(
      &includes_all(filtered_fixtures.map { |it| File.expand_path(it) })
    )
  end

  it 'should handle absolute paths with globs' do
    filewatcher = FileWatcher.new(File.expand_path('test/fixtures/**/*'))

    filewatcher.filenames.should.satisfy(
      &includes_all(fixtures.map { |it| File.expand_path(it) })
    )
  end

  it 'should handle globs' do
    filewatcher = FileWatcher.new('test/fixtures/**/*')

    filewatcher.filenames.should.satisfy(&includes_all(fixtures))
  end

  it 'should handle explicit relative paths with globs' do
    filewatcher = FileWatcher.new('./test/fixtures/**/*')

    filewatcher.filenames.should.satisfy(
      &includes_all(explicit_relative_fixtures)
    )
  end

  it 'should handle explicit relative paths' do
    filewatcher = FileWatcher.new('./test/fixtures')

    filewatcher.filenames.should.satisfy(
      &includes_all(explicit_relative_fixtures)
    )
  end

  it 'should handle tilde expansion' do
    filename = File.expand_path('~/file_watcher_1.txt')
    open(filename, 'w') { |f| f.puts 'content1' }

    filewatcher = FileWatcher.new('~/file_watcher_1.txt')

    begin
      filewatcher.filenames.should == [filename]
    ensure
      FileUtils.rm(filename)
    end
  end

  it 'should detect file deletions' do
    filename = 'test/fixtures/file1.txt'
    open(filename, 'w') { |f| f.puts 'content1' }
    filewatcher = FileWatcher.new(['test/fixtures'])
    filewatcher.filesystem_updated?.should.be.false
    FileUtils.rm(filename)
    filewatcher.filesystem_updated?.should.be.true
  end

  it 'should detect file additions' do
    filename = 'test/fixtures/file1.txt'
    FileUtils.rm(filename) if File.exist?(filename)
    filewatcher = FileWatcher.new(['test/fixtures'])
    filewatcher.filesystem_updated?.should.be.false
    open(filename, 'w') { |f| f.puts 'content1' }
    filewatcher.filesystem_updated?.should.be.true
  end

  it 'should detect file updates' do
    filename = 'test/fixtures/file1.txt'
    open(filename, 'w') { |f| f.puts 'content1' }
    filewatcher = FileWatcher.new(['test/fixtures'])
    filewatcher.filesystem_updated?.should.be.false
    sleep 1
    open(filename, 'w') { |f| f.puts 'content2' }
    filewatcher.filesystem_updated?.should.be.true
  end

  it 'should not detect file updates in delay' do
    filename = 'test/fixtures/file1.txt'
    open(filename, 'w') { |f| f.puts 'content1' }
    ## Bigger time is HACK for JRuby, that doesn't count milliseconds:
    ## https://github.com/jruby/jruby/issues/4520
    filewatcher = FileWatcher.new(['test/fixtures'], interval: 1, delay: 3)
    processed = []
    thread = Thread.new(filewatcher, processed) do
      filewatcher.watch { |changes| processed.concat(changes.keys) }
    end
    sleep 2 # thread needs a chance to start
    processed.size.should.be.zero # update block should not have been called
    open(filename, 'w') { |f| f.puts 'content3' }
    sleep 2 # Give filewatcher time to respond
    processed.size.should.equal 1 # update block should have been called
    open(filename, 'w') { |f| f.puts 'content2' }
    processed.size.should.equal 1 # update block should not have been called
    thread.exit
  end

  it 'should detect new files in subfolders' do
    FileUtils.mkdir_p subfolder

    filewatcher = FileWatcher.new(['./test/fixtures'])
    filewatcher.filesystem_updated?.should.be.false

    open(subfolder + '/file.txt', 'w') { |f| f.puts 'xyz' }
    filewatcher.filesystem_updated?.should.be.true
  end

  it 'should detect new subfolders' do
    filewatcher = FileWatcher.new(['test/fixtures'])
    filewatcher.filesystem_updated?.should.be.false

    FileUtils.mkdir_p subfolder
    filewatcher.filesystem_updated?.should.be.true
  end

  it 'should be stoppable' do
    filewatcher = FileWatcher.new(['test/fixtures'])
    thread = Thread.new(filewatcher) { filewatcher.watch(0.1) }
    sleep 0.2 # thread needs a chance to start
    filewatcher.stop
    thread.join.should.equal thread # Proves thread successfully joined
  end

  it 'should be pauseable/resumable' do
    filewatcher = FileWatcher.new(['test/fixtures'])
    filewatcher.filesystem_updated?.should.be.false
    processed = []
    Thread.new(filewatcher, processed) do
      filewatcher.watch(0.1) { |changes| processed.concat(changes.keys) }
    end
    sleep 0.2 # thread needs a chance to start
    filewatcher.pause
    (1..4).each do |n|
      open("test/fixtures/file#{n}.txt", 'w') { |f| f.puts "content#{n}" }
    end
    sleep 0.2 # Give filewatcher time to respond
    processed.should.equal [] # update block should not have been called
    filewatcher.resume
    sleep 0.2 # Give filewatcher time to respond
    processed.should.equal [] # update block still should not have been called
    added_files = []
    (5..7).each do |n|
      added_files << "test/fixtures/file#{n}.txt"
      open(added_files.last, 'w') { |f| f.puts "content#{n}" }
    end
    sleep 0.2 # Give filewatcher time to respond
    filewatcher.stop
    processed.should.satisfy(&includes_all(added_files))
  end

  it 'should process all remaining changes at finalize' do
    filewatcher = FileWatcher.new(['test/fixtures'])
    filewatcher.filesystem_updated?.should.be.false
    processed = []
    thread = Thread.new(filewatcher, processed) do
      filewatcher.watch(0.1) { |changes| processed.concat(changes.keys) }
    end
    sleep 0.2 # thread needs a chance to start
    filewatcher.stop
    thread.join
    added_files = []
    (1..4).each do |n|
      added_files << "test/fixtures/file#{n}.txt"
      open(added_files.last, 'w') { |f| f.puts "content#{n}" }
    end
    filewatcher.finalize
    puts 'What is wrong with finalize:'
    puts "Expect: #{added_files.inspect}"
    puts "Actual: #{processed.inspect}"
    # processed.should.satisfy &includes_all(added_files)
  end

  describe :VERSION do
    it 'should exist as constant' do
      FileWatcher.const_defined?(:VERSION).should.be.true
    end

    it 'should be an instance of String' do
      FileWatcher::VERSION.class.should.equal String
    end
  end
end

describe 'FileWatcher executable' do
  path = File.expand_path('../bin/filewatcher', File.dirname(__FILE__))
  tmp_dir = File.expand_path('./tmp', File.dirname(__FILE__))

  after do
    FileUtils.rm_rf tmp_dir
  end

  it 'should run' do
    system("#{path} > /dev/null").should.be.true
  end

  it 'should set correct ENV variables' do
    FileUtils.mkdir_p tmp_dir

    pid = spawn(
      "#{path} '#{tmp_dir}/foo*' 'printf \"" +
        %w[
          $FILENAME
          $BASENAME
          $EVENT
          $DIRNAME
          $ABSOLUTE_FILENAME
          $RELATIVE_FILENAME
        ].join(', ') +
      "\" > #{tmp_dir}/env'"
    )
    Process.detach(pid)
    sleep 2

    FileUtils.touch "#{tmp_dir}/foo.txt"
    sleep 2

    File.read("#{tmp_dir}/env").should.equal(
      %W[
        #{tmp_dir}/foo.txt
        foo.txt
        created
        #{tmp_dir}
        #{tmp_dir}/foo.txt
        test/tmp/foo.txt
      ].join(', ')
    )

    Process.kill('HUP', pid)
  end
end
