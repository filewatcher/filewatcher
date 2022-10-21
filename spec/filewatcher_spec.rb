# frozen_string_literal: true

require 'fileutils'
require_relative '../lib/filewatcher'

describe Filewatcher do
  subject(:processed) { watch_run.processed }

  before do
    FileUtils.mkdir_p tmp_dir
  end

  after do
    logger.debug "FileUtils.rm_r #{tmp_dir}"
    FileUtils.rm_r tmp_dir if File.exist?(tmp_dir)

    Filewatcher::SpecHelper.wait seconds: 5, interval: 0.2 do
      !File.exist?(tmp_dir)
    end
  end

  def initialize_filewatcher(path, options = {})
    described_class.new(path, options.merge(logger: logger))
  end

  def transform_spec_files(file)
    ruby_watch_run_class.transform_spec_files(file)
  end

  let(:tmp_dir) { Filewatcher::SpecHelper::WatchRun::TMP_DIR }
  let(:logger) { Filewatcher::SpecHelper.logger }

  let(:raw_file_name) { 'tmp_file.txt' }
  let(:initial_files) { { raw_file_name => {} } }

  let(:change_event) { :update }
  let(:change_directory) { false }

  let(:changes) do
    files = Array(initial_files.keys)
    files << raw_file_name if files.empty?
    files.to_h do |file|
      [transform_spec_files(file), { event: change_event, directory: change_directory }]
    end
  end

  let(:result_transformed_filename) do
    transform_spec_files(initial_files.any? ? initial_files.keys.first : raw_file_name)
  end

  let(:ruby_watch_run_class) { Filewatcher::SpecHelper::RubyWatchRun }

  ## TODO: Check its needless
  let(:every) { false }
  let(:immediate) { false }
  let(:interval) { 0.2 }
  let(:filewatcher_files) { File.expand_path('spec/tmp/**/*') }
  let(:filewatcher) do
    initialize_filewatcher filewatcher_files, interval: interval, every: every, immediate: immediate
  end

  let(:watch_run) do
    ruby_watch_run_class.new(
      initial_files: initial_files, filewatcher: filewatcher, changes: changes
    )
  end

  let(:processed_files) { watch_run.processed.flat_map(&:keys) }

  describe '.print_version' do
    subject(:method_call) { described_class.print_version }

    let(:ruby_version_regexp) { '(j|truffle)?ruby \d+\.\d+\.\d+.*' }
    let(:filewatcher_version_regexp) { "Filewatcher #{Filewatcher::VERSION}" }

    it do
      expect { method_call }.to output(
        /^#{ruby_version_regexp}\n#{filewatcher_version_regexp}$/
      ).to_stdout_from_any_process
    end
  end

  describe '#initialize' do
    describe 'regular run' do
      before { watch_run.run }

      context 'with excluding selected file patterns' do
        let(:filewatcher) do
          initialize_filewatcher(
            filewatcher_files,
            exclude: File.expand_path('spec/tmp/**/*.txt')
          )
        end

        it { is_expected.to be_empty }
      end

      context 'with absolute paths including globs' do
        let(:filewatcher_files) { File.expand_path('spec/tmp/**/*') }

        it { is_expected.to eq [{ result_transformed_filename => :updated }] }
      end

      context 'with globs' do
        let(:filewatcher_files) { 'spec/tmp/**/*' }

        it { is_expected.to eq [{ result_transformed_filename => :updated }] }
      end

      context 'with explicit relative paths with globs' do
        let(:filewatcher_files) { './spec/tmp/**/*' }

        it { is_expected.to eq [{ result_transformed_filename => :updated }] }
      end

      context 'with explicit relative paths' do
        let(:filewatcher_files) { './spec/tmp' }

        it { is_expected.to eq [{ result_transformed_filename => :updated }] }
      end

      context 'with tilde expansion' do
        let(:filewatcher_files) { '~/file_watcher_1.txt' }
        let(:raw_file_name) { File.expand_path('~/file_watcher_1.txt') }

        it { is_expected.to eq [{ raw_file_name => :updated }] }
      end

      context 'with Array of paths' do
        let(:file_1) { 'tmp_file_1.txt' }
        let(:subdir) { 'subdir' }
        let(:file_2) { "#{subdir}/tmp_file_2.txt" }

        let(:filewatcher_files) { ["spec/tmp/#{file_1}", "spec/tmp/#{subdir}"] }

        let(:initial_files) do
          {
            file_1 => {}
          }
        end

        let(:changes) do
          {
            **initial_files.to_h { |key, _value| [transform_spec_files(key), { event: :update }] },
            transform_spec_files(file_2) => { event: :create }
          }
        end

        let(:expected_changes) do
          [
            **initial_files.to_h { |key, _value| [transform_spec_files(key), :updated] },
            transform_spec_files(file_2) => :created
          ]
        end

        it { is_expected.to contain_exactly(*expected_changes) }
      end
    end

    describe '`:immediate` option' do
      before do
        watch_run.start
        watch_run.stop
      end

      context 'when is `true`' do
        let(:immediate) { true }

        it { is_expected.to eq [{ '' => '' }] }

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
    context 'when action is known' do
      before do
        FileUtils.mkdir_p subdirectory if defined? subdirectory

        watch_run.run
      end

      context 'when there are file deletions' do
        let(:change_event) { :delete }

        it { is_expected.to eq [{ result_transformed_filename => :deleted }] }
      end

      context 'when there are file additions' do
        let(:initial_files) { {} }
        let(:changes) { { result_transformed_filename => { event: :create } } }

        it { is_expected.to eq [{ result_transformed_filename => :created }] }
      end

      context 'when there are file updates' do
        let(:change_event) { :update }

        it { is_expected.to eq [{ result_transformed_filename => :updated }] }
      end

      context 'when there are new files in subdirectories' do
        let(:subdirectory) { File.expand_path('spec/tmp/new_sub_directory') }

        let(:initial_files) { {} }
        let(:created_filename) { File.join(subdirectory, 'file.txt') }
        let(:changes) { { created_filename => { event: :create } } }

        let(:every) { true }
        ## https://github.com/filewatcher/filewatcher/pull/115#issuecomment-674581595
        let(:interval) { 0.4 }

        it do
          expect(processed).to eq [
            { subdirectory => :updated, created_filename => :created }
          ]
        end
      end

      context 'when there are new subdirectories' do
        let(:initial_files) { {} }
        let(:raw_file_name) { 'new_sub_directory' }
        let(:change_event) { :create }
        let(:change_directory) { true }

        it { is_expected.to eq [{ result_transformed_filename => :created }] }
      end
    end

    context 'when action is unknown' do
      let(:change_event) { :foo }

      specify { expect { watch_run.run }.to raise_error(RuntimeError, 'Unknown change `foo`') }
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
    logger.debug "#{__method__} #{range}"

    directory = 'spec/tmp'
    FileUtils.mkdir_p directory

    range.to_a.map do |n|
      File.write(file = "#{directory}/file#{n}.txt", "content#{n}")

      Filewatcher::SpecHelper.wait seconds: 1

      file
    end
  end

  shared_context 'when paused' do
    let(:action) { :create }
    let(:every) { true }

    before do
      watch_run.start

      logger.debug 'filewatcher.pause'
      watch_run.filewatcher.pause

      Filewatcher::SpecHelper.wait seconds: 1

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
      logger.debug 'filewatcher.resume'
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
end
