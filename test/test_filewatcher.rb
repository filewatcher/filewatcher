# frozen_string_literal: true

require 'fileutils'
require_relative '../lib/filewatcher'

describe Filewatcher do
  before do
    FileUtils.mkdir_p WatchRun::TMP_DIR
  end

  after do
    FileUtils.rm_r WatchRun::TMP_DIR
  end

  describe '#initialize' do
    it 'should exclude selected file patterns' do
      wr = RubyWatchRun.new(
        filewatcher: Filewatcher.new(
          File.expand_path('test/tmp/**/*'),
          exclude: File.expand_path('test/tmp/**/*.txt')
        )
      )

      wr.run

      wr.processed.should.be.empty
    end

    it 'should handle absolute paths with globs' do
      wr = RubyWatchRun.new(
        filewatcher: Filewatcher.new(
          File.expand_path('test/tmp/**/*')
        )
      )

      wr.run

      wr.processed.should.equal(
        [[wr.filename, :updated]]
      )
    end

    it 'should handle globs' do
      wr = RubyWatchRun.new(
        filewatcher: Filewatcher.new('test/tmp/**/*')
      )

      wr.run

      wr.processed.should.equal(
        [[wr.filename, :updated]]
      )
    end

    it 'should handle explicit relative paths with globs' do
      wr = RubyWatchRun.new(
        filewatcher: Filewatcher.new('./test/tmp/**/*')
      )

      wr.run

      wr.processed.should.equal(
        [[wr.filename, :updated]]
      )
    end

    it 'should handle explicit relative paths' do
      wr = RubyWatchRun.new(
        filewatcher: Filewatcher.new('./test/tmp')
      )

      wr.run

      wr.processed.should.equal(
        [[wr.filename, :updated]]
      )
    end

    it 'should handle tilde expansion' do
      filename = File.expand_path('~/file_watcher_1.txt')

      wr = RubyWatchRun.new(
        filename: filename,
        filewatcher: Filewatcher.new('~/file_watcher_1.txt')
      )

      wr.run

      wr.processed.should.equal(
        [[filename, :updated]]
      )
    end

    it 'should immediately run with corresponding option' do
      wr = RubyWatchRun.new(
        filewatcher: Filewatcher.new('**/*', immediate: true)
      )

      wr.start
      wr.stop

      wr.processed.should.equal [['', '']]
      wr.watched.should.be > 0
    end

    it 'should not be executed without immediate option and changes' do
      wr = RubyWatchRun.new(
        filewatcher: Filewatcher.new('**/*', immediate: false)
      )

      wr.start
      wr.stop

      wr.processed.should.be.empty
      wr.watched.should.equal 0
    end
  end

  describe '#watch' do
    it 'should detect file deletions' do
      wr = RubyWatchRun.new(action: :delete)

      wr.run

      wr.processed.should.equal(
        [[wr.filename, :deleted]]
      )
    end

    it 'should detect file additions' do
      wr = RubyWatchRun.new(action: :create)

      wr.run

      wr.processed.should.equal(
        [[wr.filename, :created]]
      )
    end

    it 'should detect file updates' do
      wr = RubyWatchRun.new(action: :update)

      wr.run

      wr.processed.should.equal(
        [[wr.filename, :updated]]
      )
    end

    it 'should detect new files in subfolders' do
      FileUtils.mkdir_p subfolder = File.expand_path('test/tmp/new_sub_folder')

      wr = RubyWatchRun.new(
        filename: File.join(subfolder, 'file.txt'),
        action: :create,
        every: true
      )
      wr.run
      wr.processed.should.equal(
        [
          [subfolder, :updated],
          [wr.filename, :created]
        ]
      )
    end

    it 'should detect new subfolders' do
      subfolder = 'new_sub_folder'

      wr = RubyWatchRun.new(
        filename: subfolder,
        directory: true,
        action: :create
      )

      wr.run

      wr.processed.should.equal(
        [[wr.filename, :created]]
      )
    end
  end

  describe '#stop' do
    it 'should work' do
      wr = RubyWatchRun.new

      wr.start

      wr.filewatcher.stop

      # Proves thread successfully joined
      wr.thread.join.should.equal wr.thread
    end
  end

  describe '#pause, #resume' do
    it 'should work' do
      wr = RubyWatchRun.new(action: :create, every: true)

      wr.start

      wr.filewatcher.pause

      (1..4).each do |n|
        File.write("test/tmp/file#{n}.txt", "content#{n}")
      end
      sleep 0.2 # Give filewatcher time to respond

      # update block should not have been called
      wr.processed.should.be.empty

      wr.filewatcher.resume
      sleep 0.2 # Give filewatcher time to respond

      # update block still should not have been called
      wr.processed.should.be.empty

      added_files = (5..7).to_a.map do |n|
        File.write(file = "test/tmp/file#{n}.txt", "content#{n}")
        file
      end
      sleep 0.2 # Give filewatcher time to respond

      wr.filewatcher.stop
      wr.stop
      wr.processed.map(&:first).should include_all_files(added_files)
    end
  end

  describe '#finalize' do
    it 'should process all remaining changes' do
      wr = RubyWatchRun.new(action: :create, every: true)

      wr.start

      wr.filewatcher.stop
      wr.thread.join

      added_files = (1..4).to_a.map do |n|
        File.write(file = "test/tmp/file#{n}.txt", "content#{n}")
        file
      end

      wr.filewatcher.finalize

      wr.processed.map(&:first).should include_all_files(added_files)
    end
  end

  describe 'executable' do
    tmp_dir = ShellWatchRun::TMP_DIR

    it 'should run' do
      null_output = Gem.win_platform? ? 'NUL' : '/dev/null'
      system("#{ShellWatchRun::EXECUTABLE} > #{null_output}")
        .should.be.true
    end

    it 'should set correct ENV variables' do
      filename = 'foo.txt'

      swr = ShellWatchRun.new(
        filename: filename,
        action: :create,
        dumper: :env
      )

      swr.run

      File.read(swr.output)
        .should.equal(
          %W[
            #{tmp_dir}/#{filename}
            #{filename}
            created
            #{tmp_dir}
            #{tmp_dir}/#{filename}
            test/tmp/#{filename}
          ].join(', ')
        )
    end

    it 'should be executed immediately with corresponding option' do
      swr = ShellWatchRun.new(
        options: '--immediate',
        dumper: :watched
      )

      swr.start
      swr.stop

      File.exist?(swr.output).should.be.true
      File.read(swr.output).should.equal 'watched'
    end

    it 'should not be executed without immediate option and changes' do
      swr = ShellWatchRun.new(
        options: '',
        dumper: :watched
      )

      swr.start
      swr.stop

      File.exist?(swr.output).should.be.false
    end
  end
end
