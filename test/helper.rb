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
      filename =~ %r{^(/|~|[A-Z]:)} ? filename : File.join(TMP_DIR, filename)
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
  end
end

class RubyWatchRun < WatchRun
  SLEEP_MULTIPLIER = Gem::Platform.local.os == 'darwin' ? 5 : 1

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
    # thread needs a chance to start
    wait 12 do
      filewatcher.keep_watching
    end

    # a little more time
    sleep 1 * SLEEP_MULTIPLIER
  end

  def stop
    thread.exit

    wait 12 do
      thread.stop?
    end

    # a little more time
    sleep 1 * SLEEP_MULTIPLIER

    super
  end

  private

  def make_changes
    super

    # Some OS, filesystems and Ruby interpretators
    # doesn't catch milliseconds of `File.mtime`
    wait 12 do
      processed.any?
    end
  end

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

  def wait(seconds)
    max_count = seconds / filewatcher.interval
    count = 0
    while count < max_count && !yield
      sleep filewatcher.interval
      count += 1
    end
  end
end

class ShellWatchRun < WatchRun
  EXECUTABLE = "#{'ruby ' if Gem.win_platform?}" \
    "#{File.realpath File.join(__dir__, '..', 'bin', 'filewatcher')}".freeze

  SLEEP_MULTIPLIER = RUBY_PLATFORM == 'java' ? 5 : 1

  ENV_FILE = File.join(TMP_DIR, 'env')

  def initialize(
    options: {},
    dumper: :watched,
    **args
  )
    super(**args)
    @options = options
    @options[:interval] ||= 0.1
    @options_string =
      @options.map { |key, value| "--#{key}=#{value}" }.join(' ')
    @dumper = dumper
  end

  def start
    super

    @pid = spawn_filewatcher

    Process.detach(@pid)

    wait 12 do
      pid_state == 'S' && (!@options[:immediate] || File.exist?(ENV_FILE))
    end

    # a little more time
    sleep 1 * SLEEP_MULTIPLIER
  end

  def stop
    kill_filewatcher

    wait 12 do
      pid_state.empty?
    end

    # a little more time
    sleep 1 * SLEEP_MULTIPLIER

    super
  end

  private

  SPAWN_OPTIONS = Gem.win_platform? ? {} : { pgroup: true }

  def spawn_filewatcher
    spawn(
      "#{EXECUTABLE} #{@options_string} \"#{@filename}\"" \
        " \"ruby #{File.join(__dir__, "dumpers/#{@dumper}_dumper.rb")}\"",
      **SPAWN_OPTIONS
    )
  end

  def make_changes
    super

    wait 12 do
      File.exist?(ENV_FILE)
    end
  end

  def kill_filewatcher
    if Gem.win_platform?
      Process.kill('KILL', @pid)
    else
      ## Problems: https://github.com/thomasfl/filewatcher/pull/83
      ## Solution: https://stackoverflow.com/a/45032252/2630849
      Process.kill('TERM', -Process.getpgid(@pid))
      Process.waitall
    end
  end

  def pid_state
    ## For macOS output:
    ## https://travis-ci.org/thomasfl/filewatcher/jobs/304433538
    `ps -ho state -p #{@pid}`.sub('STAT', '').strip
  end

  def wait(seconds)
    max_count = seconds / @options[:interval]
    count = 0
    while count < max_count && !yield
      sleep @options[:interval]
      count += 1
    end
  end
end

custom_matcher :include_all_files do |obj, elements|
  elements.all? { |element| obj.include? File.expand_path(element) }
end

def dump_to_env_file(content)
  File.write File.join(ShellWatchRun::ENV_FILE), content
end
