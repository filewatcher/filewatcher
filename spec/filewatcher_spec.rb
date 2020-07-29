# frozen_string_literal: true

require 'fileutils'
require_relative '../lib/filewatcher'

describe Filewatcher do
  subject(:processed) { watch_run.processed }

  before do
    FileUtils.mkdir_p WatchRun::TMP_DIR
  end

  after do
    LOGGER.debug "FileUtils.rm_r #{WatchRun::TMP_DIR}"
    FileUtils.rm_r WatchRun::TMP_DIR

    wait seconds: 5, interval: 0.2 do
      !File.exist?(WatchRun::TMP_DIR)
    end
  end

  def initialize_filewatcher(path, options = {})
    described_class.new(path, options.merge(logger: LOGGER))
  end

  let(:filename) { 'tmp_file.txt' }
  let(:action) { :update }
  let(:directory) { false }
  let(:every) { false }
  let(:immediate) { false }
  let(:filewatcher) do
    initialize_filewatcher(
      File.join(WatchRun::TMP_DIR, '**', '*'),
      interval: 0.2, every: every, immediate: immediate
    )
  end

  let(:watch_run) do
    RubyWatchRun.new(
      filename: filename, filewatcher: filewatcher, action: action,
      directory: directory
    )
  end

  let(:processed_files) { watch_run.processed.map(&:first) }

  describe '#initialize' do
    describe 'regular run' do
      before { watch_run.run }

      context 'with excluding selected file patterns' do
        let(:filewatcher) do
          initialize_filewatcher(
            File.expand_path('spec/tmp/**/*'),
            exclude: File.expand_path('spec/tmp/**/*.txt')
          )
        end

        it { is_expected.to be_empty }
      end

      context 'with absolute paths including globs' do
        let(:filewatcher) do
          initialize_filewatcher(
            File.expand_path('spec/tmp/**/*')
          )
        end

        it { is_expected.to eq [[watch_run.filename, :updated]] }
      end

      context 'with globs' do
        let(:filewatcher) { initialize_filewatcher('spec/tmp/**/*') }

        it { is_expected.to eq [[watch_run.filename, :updated]] }
      end

      context 'with explicit relative paths with globs' do
        let(:filewatcher) { initialize_filewatcher('./spec/tmp/**/*') }

        it { is_expected.to eq [[watch_run.filename, :updated]] }
      end

      context 'with explicit relative paths' do
        let(:filewatcher) { initialize_filewatcher('./spec/tmp') }

        it { is_expected.to eq [[watch_run.filename, :updated]] }
      end

      context 'with tilde expansion' do
        let(:filename) { File.expand_path('~/file_watcher_1.txt') }

        let(:filewatcher) { initialize_filewatcher('~/file_watcher_1.txt') }

        it { is_expected.to eq [[filename, :updated]] }
      end
    end

    describe '`:immediate` option' do
      before do
        watch_run.start
        watch_run.stop
      end

      context 'when is `true`' do
        let(:immediate) { true }

        it { is_expected.to eq [['', '']] }

        describe 'when watched' do
          subject { watch_run.watched }

          it { is_expected.to be > 0 }
        end
      end

      context 'when is `false`' do
        let(:immediate) { false }

        it { is_expected.to be_empty }

        describe 'when watched' do
          subject { watch_run.watched }

          it { is_expected.to eq 0 }
        end
      end
    end
  end

  describe '#watch' do
    before do
      FileUtils.mkdir_p subdirectory if defined? subdirectory

      watch_run.run
    end

    describe 'detecting file deletions' do
      let(:action) { :delete }

      it { is_expected.to eq [[watch_run.filename, :deleted]] }
    end

    context 'when there are file additions' do
      let(:action) { :create }

      it { is_expected.to eq [[watch_run.filename, :created]] }
    end

    context 'when there are file updates' do
      let(:action) { :update }

      it { is_expected.to eq [[watch_run.filename, :updated]] }
    end

    context 'when there are new files in subdirectories' do
      let(:subdirectory) { File.expand_path('spec/tmp/new_sub_directory') }

      let(:filename) { File.join(subdirectory, 'file.txt') }
      let(:action) { :create }
      let(:every) { true }

      it do
        expect(processed).to eq [
          [subdirectory, :updated], [watch_run.filename, :created]
        ]
      end
    end

    context 'when there are new subdirectories' do
      let(:filename) { 'new_sub_directory' }
      let(:directory) { true }
      let(:action) { :create }

      it { is_expected.to eq [[watch_run.filename, :created]] }
    end
  end

  describe '#stop' do
    subject { watch_run.thread.join }

    before do
      watch_run.start
      watch_run.filewatcher.stop
    end

    it { is_expected.to eq watch_run.thread }
  end

  def write_tmp_files(range)
    LOGGER.debug "#{__method__} #{range}"

    directory = 'spec/tmp'
    FileUtils.mkdir_p directory

    range.to_a.map do |n|
      File.write(file = "#{directory}/file#{n}.txt", "content#{n}")
      file
    end
  end

  shared_context 'when paused' do
    let(:action) { :create }
    let(:every) { true }

    before do
      watch_run.start
      LOGGER.debug 'filewatcher.pause'
      watch_run.filewatcher.pause

      write_tmp_files 1..4
    end
  end

  describe '#pause' do
    include_context 'when paused'

    # update block should not have been called
    it { is_expected.to be_empty }
  end

  describe '#resume' do
    include_context 'when paused'

    before do
      LOGGER.debug 'filewatcher.resume'
      watch_run.filewatcher.resume
    end

    after do
      watch_run.stop
    end

    describe 'changes while paused' do
      # update block still should not have been called
      it { is_expected.to be_empty }
    end

    describe 'changes after resumed' do
      subject { processed_files }

      let(:added_files) { write_tmp_files 5..7 }

      before do
        added_files

        watch_run.wait

        watch_run.filewatcher.stop
        watch_run.stop
      end

      it { is_expected.to include_all_files added_files }
    end
  end

  describe '#finalize' do
    subject { processed_files }

    let(:action) { :create }
    let(:every) { true }

    let(:added_files) { write_tmp_files 1..4 }

    before do
      watch_run.start
      watch_run.filewatcher.stop
      watch_run.thread.join

      added_files

      watch_run.filewatcher.finalize
    end

    it { is_expected.to include_all_files added_files }
  end

  describe 'executable' do
    let(:tmp_dir) { ShellWatchRun::TMP_DIR }
    let(:null_output) { Gem.win_platform? ? 'NUL' : '/dev/null' }
    let(:dumper) { :watched }
    let(:options) { {} }
    let(:watch_run) do
      ShellWatchRun.new(
        filename: filename,
        action: action,
        directory: directory,
        dumper: dumper,
        options: options
      )
    end

    let(:dump_file_content) { File.read(ShellWatchRun::DUMP_FILE) }
    let(:expected_dump_file_existence) { true }
    let(:expected_dump_file_content) { 'watched' }

    shared_examples 'dump file existence' do
      describe 'file existence' do
        subject { File.exist?(ShellWatchRun::DUMP_FILE) }

        it { is_expected.to be expected_dump_file_existence }
      end
    end

    shared_examples 'dump file content' do
      describe 'file content' do
        subject { dump_file_content }

        it { is_expected.to eq expected_dump_file_content }
      end
    end

    describe 'just run' do
      subject { system("#{ShellWatchRun::EXECUTABLE} > #{null_output}") }

      it { is_expected.to be true }
    end

    describe 'ENV variables' do
      let(:filename) { 'foo.txt' }
      let(:dumper) { :env }

      before do
        watch_run.run
      end

      context 'when file created' do
        let(:action) { :create }

        let(:expected_dump_file_content) do
          %W[
            #{tmp_dir}/#{filename}
            #{filename}
            created
            #{tmp_dir}
            #{tmp_dir}/#{filename}
            spec/tmp/#{filename}
          ].join(', ')
        end

        include_examples 'dump file existence'

        include_examples 'dump file content'
      end

      context 'when file deleted' do
        let(:action) { :delete }

        let(:expected_dump_file_content) do
          %W[
            #{tmp_dir}/#{filename}
            #{filename}
            deleted
            #{tmp_dir}
            #{tmp_dir}/#{filename}
            spec/tmp/#{filename}
          ].join(', ')
        end

        include_examples 'dump file existence'

        include_examples 'dump file content'
      end
    end

    shared_context 'when started and stopped' do
      before do
        watch_run.start
        watch_run.stop
      end
    end

    describe '`--immediate` option' do
      let(:options) { { immediate: true } }

      include_context 'when started and stopped'

      include_examples 'dump file existence'

      include_examples 'dump file content'
    end

    context 'without immediate option and changes' do
      let(:options) { {} }
      let(:expected_dump_file_existence) { false }

      include_context 'when started and stopped'

      include_examples 'dump file existence'
    end

    describe '`--restart` option' do
      let(:options) { { restart: true } }

      before do
        watch_run.run
      end

      include_examples 'dump file existence'

      include_examples 'dump file content'
    end
  end
end
