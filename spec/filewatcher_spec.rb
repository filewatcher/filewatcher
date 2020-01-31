# frozen_string_literal: true

require 'fileutils'
require_relative '../lib/filewatcher'

describe Filewatcher do
  before do
    FileUtils.mkdir_p WatchRun::TMP_DIR
  end

  after do
    LOGGER.debug "FileUtils.rm_r #{WatchRun::TMP_DIR}"
    FileUtils.rm_r WatchRun::TMP_DIR

    interval = 0.2
    wait = 5
    count = 0
    while File.exist?(WatchRun::TMP_DIR) && count < (wait / interval)
      sleep interval
    end
  end

  let(:filename) { 'tmp_file.txt' }
  let(:action) { :update }
  let(:directory) { false }
  let(:every) { false }
  let(:immediate) { false }
  let(:filewatcher) do
    Filewatcher.new(
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

  let(:processed) { watch_run.processed }
  let(:processed_files) { watch_run.processed.map(&:first) }

  subject { processed }

  describe '#initialize' do
    describe 'regular run' do
      before { watch_run.run }

      context 'exclude selected file patterns' do
        let(:filewatcher) do
          Filewatcher.new(
            File.expand_path('spec/tmp/**/*'),
            exclude: File.expand_path('spec/tmp/**/*.txt')
          )
        end

        it { is_expected.to be_empty }
      end

      context 'absolute paths with globs' do
        let(:filewatcher) do
          Filewatcher.new(
            File.expand_path('spec/tmp/**/*')
          )
        end

        it { is_expected.to eq [[watch_run.filename, :updated]] }
      end

      context 'globs' do
        let(:filewatcher) { Filewatcher.new('spec/tmp/**/*') }

        it { is_expected.to eq [[watch_run.filename, :updated]] }
      end

      context 'explicit relative paths with globs' do
        let(:filewatcher) { Filewatcher.new('./spec/tmp/**/*') }

        it { is_expected.to eq [[watch_run.filename, :updated]] }
      end

      context 'explicit relative paths' do
        let(:filewatcher) { Filewatcher.new('./spec/tmp') }

        it { is_expected.to eq [[watch_run.filename, :updated]] }
      end

      context 'tilde expansion' do
        let(:filename) { File.expand_path('~/file_watcher_1.txt') }

        let(:filewatcher) { Filewatcher.new('~/file_watcher_1.txt') }

        it { is_expected.to eq [[filename, :updated]] }
      end
    end

    describe '`:immediate` option' do
      before do
        watch_run.start
        watch_run.stop
      end

      context 'is `true`' do
        let(:immediate) { true }

        it { is_expected.to eq [['', '']] }

        describe 'watched' do
          subject { watch_run.watched }

          it { is_expected.to be > 0 }
        end
      end

      context 'is `false`' do
        let(:immediate) { false }

        it { is_expected.to be_empty }

        describe 'watched' do
          subject { watch_run.watched }

          it { is_expected.to eq 0 }
        end
      end
    end
  end

  describe '#watch' do
    before do
      FileUtils.mkdir_p subfolder if defined? subfolder

      watch_run.run
    end

    describe 'detecting file deletions' do
      let(:action) { :delete }

      it { is_expected.to eq [[watch_run.filename, :deleted]] }
    end

    context 'detecting file additions' do
      let(:action) { :create }

      it { is_expected.to eq [[watch_run.filename, :created]] }
    end

    context 'detecting file updates' do
      let(:action) { :update }

      it { is_expected.to eq [[watch_run.filename, :updated]] }
    end

    context 'detecting new files in subfolders' do
      let(:subfolder) { File.expand_path('spec/tmp/new_sub_folder') }

      let(:filename) { File.join(subfolder, 'file.txt') }
      let(:action) { :create }
      let(:every) { true }

      it do
        is_expected.to eq [
          [subfolder, :updated], [watch_run.filename, :created]
        ]
      end
    end

    context 'detecting new subfolders' do
      let(:filename) { 'new_sub_folder' }
      let(:directory) { true }
      let(:action) { :create }

      it { is_expected.to eq [[watch_run.filename, :created]] }
    end
  end

  describe '#stop' do
    before do
      watch_run.start
      watch_run.filewatcher.stop
    end

    subject { watch_run.thread.join }

    it { is_expected.to eq watch_run.thread }
  end

  def write_tmp_files(range)
    LOGGER.debug "#{__method__} #{range}"

    directory = 'spec/tmp'
    FileUtils.mkdir_p directory

    result = range.to_a.map do |n|
      File.write(file = "#{directory}/file#{n}.txt", "content#{n}")
      file
    end

    result
  end

  shared_context 'paused' do
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
    include_context 'paused'

    # update block should not have been called
    it { is_expected.to be_empty }
  end

  describe '#resume' do
    include_context 'paused'

    before do
      LOGGER.debug 'filewatcher.resume'
      watch_run.filewatcher.resume
    end

    context 'changes while paused' do
      # update block still should not have been called
      it { is_expected.to be_empty }
    end

    context 'changes after resumed' do
      before do
        @added_files = write_tmp_files 5..7

        watch_run.wait

        watch_run.filewatcher.stop
        watch_run.stop
      end

      subject { processed_files }

      it { is_expected.to include_all_files @added_files }
    end
  end

  describe '#finalize' do
    let(:action) { :create }
    let(:every) { true }

    before do
      watch_run.start
      watch_run.filewatcher.stop
      watch_run.thread.join
    end

    let!(:added_files) { write_tmp_files 1..4 }

    before do
      watch_run.filewatcher.finalize
    end

    subject { processed_files }

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

      subject { File.read(ShellWatchRun::ENV_FILE) }

      context 'file creation' do
        let(:action) { :create }

        it do
          is_expected.to eq %W[
            #{tmp_dir}/#{filename}
            #{filename}
            created
            #{tmp_dir}
            #{tmp_dir}/#{filename}
            spec/tmp/#{filename}
          ].join(', ')
        end
      end

      context 'file deletion' do
        let(:action) { :delete }

        it do
          is_expected.to eq %W[
            #{tmp_dir}/#{filename}
            #{filename}
            deleted
            #{tmp_dir}
            #{tmp_dir}/#{filename}
            spec/tmp/#{filename}
          ].join(', ')
        end
      end
    end

    shared_context 'start and stop' do
      before do
        watch_run.start
        watch_run.stop
      end
    end

    shared_examples 'ENV file existance' do
      describe 'file existance' do
        subject { File.exist?(ShellWatchRun::ENV_FILE) }

        it { is_expected.to be expected_existance }
      end
    end

    shared_examples 'ENV file content' do
      describe 'file content' do
        subject { File.read(ShellWatchRun::ENV_FILE) }

        it { is_expected.to eq 'watched' }
      end
    end

    describe '`:immediate` option' do
      let(:options) { { immediate: true } }

      include_context 'start and stop'

      let(:expected_existance) { true }
      include_examples 'ENV file existance'

      include_examples 'ENV file content'
    end

    context 'without immediate option and changes' do
      let(:options) { {} }

      include_context 'start and stop'

      let(:expected_existance) { false }
      include_examples 'ENV file existance'
    end

    describe '`:restart` option' do
      let(:options) { { restart: true } }

      before do
        watch_run.run
      end

      let(:expected_existance) { true }
      include_examples 'ENV file existance'

      include_examples 'ENV file content'
    end
  end
end
