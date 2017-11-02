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
    # thread needs a chance to start
    wait 3 do
      filewatcher.keep_watching
    end
  end

  def stop
    thread.exit

    wait 3 do
      thread.stop?
    end

    super
  end

  private

  def make_changes
    super

    # Some OS, filesystems and Ruby interpretators
    # doesn't catch milliseconds of `File.mtime`
    wait 3 do
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

    @pid = spawn(
      "#{EXECUTABLE} #{@options_string} \"#{@filename}\"" \
        " \"ruby #{File.join(__dir__, 'dumpers', "#{@dumper}_dumper.rb")}\""
    )

    Process.detach(@pid)

    wait 12 do
      pid_state == 'S' && (!@options[:immediate] || File.exist?(ENV_FILE))
    end

    # a little more time
    sleep 1
  end

  def stop
    super

    Process.kill('KILL', @pid)

    wait 12 do
      pid_state.empty?
    end

    # a little more time
    sleep 1
  end

  private

  def make_changes
    super
    wait 12 do
      File.exist?(ENV_FILE)
    end
  end

  def pid_state
    `ps -ho state -p #{@pid}`.chomp
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
