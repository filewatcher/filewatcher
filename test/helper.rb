# frozen_string_literal: true

require 'bacon'
require 'bacon/custom_matchers_messages'

begin
  require 'pry-byebug'
rescue LoadError
  nil
end

class WatchRun
  TMP_DIR = File.join(__dir__, 'tmp')

  attr_reader :filename

  def initialize(
    filename: 'tmp_file.txt',
    directory: false,
    action: :update
  )
    @filename =
      filename.start_with?('/', '~') ? filename : File.join(TMP_DIR, filename)
    @directory = directory
    @action = action
  end

  def start
    File.write(@filename, 'content1') unless @action == :create
  end

  def run
    start

    make_changes

    stop
  end

  def stop
    FileUtils.rm_r(@filename) if File.exist?(@filename)
  end

  private

  def make_changes
    if @action == :delete
      FileUtils.remove(@filename)
    elsif @directory
      FileUtils.mkdir_p(@filename)
    else
      File.write(@filename, 'content2')
    end

    # Some OS, filesystems and Ruby interpretators
    # doesn't catch milliseconds of `File.mtime`
    sleep 3
  end
end

class RubyWatchRun < WatchRun
  attr_reader :filewatcher, :thread, :watched, :processed

  def initialize(
    every: false,
    filewatcher: Filewatcher.new(
      File.join(TMP_DIR, '**', '*'), interval: 0.1, every: every
    ),
    **args
  )
    super(**args)
    @filewatcher = filewatcher
  end

  def start
    super
    @thread = thread_initialize
    sleep 3 # thread needs a chance to start
  end

  def stop
    super
    @thread.exit
    sleep 3
  end

  private

  def thread_initialize
    @watched ||= 0
    Thread.new(
      @filewatcher, @processed = []
    ) do |filewatcher, processed|
      filewatcher.watch do |filename, event|
        increment_watched
        processed.push([filename, event])
      end
    end
  end

  def increment_watched
    @watched += 1
  end
end

class ShellWatchRun < WatchRun
  EXECUTABLE = "#{'ruby ' if Gem.win_platform?}" \
    "#{File.realpath File.join(__dir__, '..', 'bin', 'filewatcher')}".freeze

  attr_reader :output

  def initialize(
    options: '',
    dumper: :watched,
    output: File.join(TMP_DIR, 'env'),
    **args
  )
    super(**args)
    @options = options
    @dumper = dumper
    @output = output
  end

  def start
    super

    @pid = spawn(
      "#{EXECUTABLE} #{@options} \"#{@filename}\"" \
        " \"ruby #{File.join(__dir__, 'dumpers', "#{@dumper}_dumper.rb")}\""
    )
    Process.detach(@pid)
    sleep 12
  end

  def stop
    super
    Process.kill('KILL', @pid)
    sleep 6
  end

  private

  def make_changes
    super
    sleep 9 # + 3 from base class
  end
end

custom_matcher :include_all_files do |obj, elements|
  elements.all? { |element| obj.include? File.expand_path(element) }
end

def dump_to_env_file(content)
  File.write File.join(WatchRun::TMP_DIR, 'env'), content
end
