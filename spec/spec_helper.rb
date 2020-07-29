# frozen_string_literal: true

require 'logger'

begin
  require 'pry-byebug'
rescue LoadError
  nil
end

LOGGER = Logger.new($stdout, level: :debug)

ENVIRONMENT_SPECS_COEFFICIENTS = {
  -> { ENV['CI'] } => 1,
  -> { RUBY_PLATFORM == 'java' } => 3,
  ## https://cirrus-ci.com/build/6442339705028608
  -> { RUBY_PLATFORM == 'java' && ENV['CI'] && is_a?(ShellWatchRun) } => 2,
  -> { Gem::Platform.local.os == 'darwin' } => 1
}.freeze

def wait(seconds: 1, interval: 1, &block)
  ENVIRONMENT_SPECS_COEFFICIENTS.each do |condition, coefficient|
    interval *= coefficient if instance_exec(&condition)
    seconds *= coefficient if instance_exec(&condition)
  end
  if block_given?
    wait_with_block seconds, interval, &block
  else
    wait_without_block seconds
  end
end

def wait_with_block(seconds, interval, &_block)
  (seconds / interval).ceil.times do
    break if yield

    debug "sleep interval #{interval}"
    sleep interval
  end
end

def wait_without_block(seconds)
  debug "sleep without intervals #{seconds}"
  sleep seconds
end

def debug(string)
  LOGGER.debug "Thread ##{Thread.current.object_id} #{string}"
end

class WatchRun
  TMP_DIR = File.join(__dir__, 'tmp')

  attr_reader :filename

  def initialize(filename:, action:, directory:)
    @filename =
      if filename.match? %r{^(/|~|[A-Z]:)} then filename
      else File.join(TMP_DIR, filename)
      end
    @directory = directory
    @action = action
    debug "action = #{action}"
  end

  def start
    debug 'start'
    File.write(@filename, 'content1') unless @action == :create

    wait seconds: 1
  end

  def run
    start

    make_changes

    stop
  end

  def stop
    debug 'stop'
    FileUtils.rm_r(@filename) if File.exist?(@filename)
  end

  private

  def make_changes
    debug "make changes, @action = #{@action}, @filename = #{@filename}"

    if @action == :delete
      FileUtils.remove(@filename)
    elsif @directory
      FileUtils.mkdir_p(@filename)
    else
      ## There is no `File.write` because of strange difference in parallel `File.mtime`
      ## https://cirrus-ci.com/task/6107605053472768?command=test#L497-L511
      system "echo 'content2' > #{@filename}"
      debug_file_mtime
    end

    wait seconds: 1
  end

  def debug_file_mtime
    debug "stat #{@filename}: #{Filewatcher.system_stat(@filename)}"
    debug "File.mtime = #{File.mtime(@filename).strftime('%F %T.%9N')}"
  end
end

class RubyWatchRun < WatchRun
  attr_reader :filewatcher, :thread, :watched, :processed

  def initialize(filewatcher:, **args)
    super(**args)
    @filewatcher = filewatcher

    @mutex = Mutex.new
  end

  def start
    super
    @thread = thread_initialize
    # thread needs a chance to start
    wait seconds: 1
    wait do
      keep_watching = filewatcher.keep_watching
      debug "keep_watching = #{keep_watching}"
      keep_watching
    end
  end

  def stop
    thread.exit

    wait do
      thread.stop?
    end

    super
  end

  def wait(seconds: 1)
    super seconds: seconds, interval: filewatcher.interval
  end

  private

  def make_changes
    super

    # Some OS, file systems and Ruby interpretators
    # doesn't catch milliseconds of `File.mtime`
    wait do
      @mutex.synchronize do
        debug "processed = #{processed}"
        debug "processed.any? = #{processed.any?}"
        processed.any?
      end
    end
  end

  def thread_initialize
    @watched ||= 0
    @processed = []
    Thread.new { setup_filewatcher }
  end

  def setup_filewatcher
    debug 'setup_filewatcher'
    debug filewatcher.inspect
    filewatcher.watch do |filename, event|
      debug filewatcher.inspect
      @mutex.synchronize do
        debug "watch callback: filename = #{filename}, event = #{event}"
        increment_watched
        @processed.push([filename, event])
        # debug 'pushed to processed'
      end
    end
  end

  def increment_watched
    @watched += 1
  end
end

class ShellWatchRun < WatchRun
  EXECUTABLE = "#{'ruby ' if Gem.win_platform?}" \
    "#{File.realpath File.join(__dir__, '..', 'bin', 'filewatcher')}"

  DUMP_FILE = File.join(TMP_DIR, 'dump')

  def initialize(options:, dumper:, **args)
    super(**args)
    @options = options
    @options[:interval] ||= 0.2
    @options_string =
      @options.map { |key, value| "--#{key}=#{value}" }.join(' ')
    debug "options = #{@options_string}"
    @dumper = dumper
    debug "dumper = #{@dumper}"
  end

  def start
    super

    spawn_filewatcher

    wait seconds: 1

    wait do
      debug "pid state = #{pid_state}"
      debug "#{__method__}: File.exist?(DUMP_FILE) = #{File.exist?(DUMP_FILE)}"
      pid_state == 'S' && (!@options[:immediate] || File.exist?(DUMP_FILE))
    end
  end

  def stop
    kill_filewatcher

    wait do
      pid_state.empty?
    end

    super
  end

  private

  SPAWN_OPTIONS = Gem.win_platform? ? {} : { pgroup: true }

  def spawn_filewatcher
    spawn_command = "#{EXECUTABLE} #{@options_string} \"#{@filename}\"" \
      " \"ruby #{File.join(__dir__, "dumpers/#{@dumper}_dumper.rb")}\""
    debug "spawn_command = #{spawn_command}"
    @pid = spawn spawn_command, **SPAWN_OPTIONS

    debug "@pid = #{@pid}"

    debug Process.detach(@pid)
  end

  def make_changes
    super

    wait do
      debug "#{__method__}: File.exist?(DUMP_FILE) = #{File.exist?(DUMP_FILE)}"
      File.exist?(DUMP_FILE)
    end
  end

  def kill_filewatcher
    debug __method__
    if Gem.win_platform?
      Process.kill('KILL', @pid)
    else
      ## Problems: https://github.com/thomasfl/filewatcher/pull/83
      ## Solution: https://stackoverflow.com/a/45032252/2630849
      Process.kill('TERM', -Process.getpgid(@pid))
      Process.waitall
    end
    wait
  end

  def pid_state
    ## For macOS output:
    ## https://travis-ci.org/thomasfl/filewatcher/jobs/304433538
    `ps -ho state -p #{@pid}`.sub('STAT', '').strip
  end

  def wait(seconds: 1)
    super seconds: seconds, interval: @options[:interval]
  end
end

def dump_to_file(content)
  File.write File.join(ShellWatchRun::DUMP_FILE), content
end

## For case when required from dumpers
if Object.const_defined?(:RSpec)
  RSpec::Matchers.define :include_all_files do |expected|
    match do |actual|
      expected.all? { |file| actual.include? File.expand_path(file) }
    end
  end
end
