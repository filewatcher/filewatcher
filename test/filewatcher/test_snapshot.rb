# frozen_string_literal: true

require_relative '../../lib/filewatcher/snapshot'

describe Filewatcher::Snapshot do
  before do
    @times = 4
    @files = (1..@times).map do |n|
      File.join(WatchRun::TMP_DIR, "file#{n}.txt")
    end

    FileUtils.mkdir_p WatchRun::TMP_DIR

    @files.each_with_index do |file, n|
      File.write file, "content#{n}"
    end

    @init = proc do
      Filewatcher::Snapshot.new Dir[
        File.join(WatchRun::TMP_DIR, '**', '*')
      ]
    end
  end

  after do
    FileUtils.rm_r WatchRun::TMP_DIR
  end

  describe '#initialize' do
    it 'should take snapshot of current filesystem state' do
      snapshot = @init.call

      snapshot.each do |filename, snapshot_file|
        snapshot_file.mtime.should.equal File.mtime(filename)
        snapshot_file.atime.should.equal File.atime(filename)
      end
    end
  end

  describe '#-' do
    it 'should return hash with filename => event' do
      first_snapshot = @init.call

      sleep 0.1

      File.write @files[1], 'new content'
      File.read @files[2]
      File.delete @files[3]
      new_file = File.join(WatchRun::TMP_DIR, 'file5.txt')
      File.write(new_file, 'new file')

      second_snapshot = @init.call

      (second_snapshot - first_snapshot).should.equal(
        @files[1] => :updated,
        @files[2] => :readed,
        @files[3] => :deleted,
        new_file => :created
      )
    end
  end
end
