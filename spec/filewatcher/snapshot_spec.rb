# frozen_string_literal: true

require_relative '../../lib/filewatcher/snapshot'

describe Filewatcher::Snapshot do
  let(:tmp_dir) { Filewatcher::SpecHelper::WatchRun::TMP_DIR }

  let(:tmp_files) do
    (1..4).map do |n|
      File.join(tmp_dir, "file#{n}.txt")
    end
  end

  def initialize_snapshot
    described_class.new Dir[
      File.join(tmp_dir, '**', '*')
    ]
  end

  before do
    FileUtils.mkdir_p tmp_dir

    tmp_files.each_with_index do |tmp_file, n|
      File.write tmp_file, "content#{n}"
    end
  end

  after do
    FileUtils.rm_r tmp_dir
  end

  describe '#initialize' do
    subject(:snapshot) { initialize_snapshot }

    it do
      snapshot.each do |filename, snapshot_file|
        expect(snapshot_file.mtime).to eq File.mtime(filename)
      end
    end
  end

  describe '#-' do
    subject(:difference) { second_snapshot - first_snapshot }

    let(:first_snapshot) { initialize_snapshot }
    let(:second_snapshot) { initialize_snapshot }
    let(:new_file) { File.join(tmp_dir, 'file5.txt') }

    before do
      first_snapshot

      sleep 0.1

      File.write tmp_files[1], 'new content'
      File.delete tmp_files[2]
      File.write(new_file, 'new file')
    end

    it do
      expect(difference).to eq(
        tmp_files[1] => :updated,
        tmp_files[2] => :deleted,
        new_file => :created
      )
    end
  end
end
