# frozen_string_literal: true

require 'logger'
require_relative 'filewatcher/cycles'
require_relative 'filewatcher/snapshots'

# Simple file watcher. Detect changes in files and directories.
#
# Issues: Currently doesn't monitor changes in directory names
class Filewatcher
  include Filewatcher::Cycles
  include Filewatcher::Snapshots

  attr_accessor :interval
  attr_reader :keep_watching

  def initialize(unexpanded_filenames, options = {})
    @unexpanded_filenames = unexpanded_filenames
    @unexpanded_excluded_filenames = options[:exclude]
    @keep_watching = false
    @pausing = false
    @immediate = options[:immediate]
    @interval = options.fetch(:interval, 0.5)
    @logger = options.fetch(:logger, Logger.new($stdout, level: :info))

    after_initialize unexpanded_filenames, options
  end

  def watch(&on_update)
    ## The set of available signals depends on the OS
    ## Windows doesn't support `HUP` signal, for example
    (%w[HUP INT TERM] & Signal.list.keys).each do |signal|
      trap(signal) { exit }
    end

    @on_update = on_update
    @keep_watching = true
    yield({ '' => '' }) if @immediate

    main_cycle

    @end_snapshot = current_snapshot
    finalize(&on_update)
  end

  def pause
    @pausing = true

    before_pause_sleep

    # Ensure we wait long enough to enter pause loop in #watch
    sleep @interval
  end

  def resume
    raise "Can't resume unless #watch and #pause were first called" if !@keep_watching || !@pausing

    @last_snapshot = current_snapshot # resume with fresh snapshot
    @pausing = false

    before_resume_sleep

    sleep @interval # Wait long enough to exit pause loop in #watch
  end

  # Ends the watch, allowing any remaining changes to be finalized.
  # Used mainly in multi-threaded situations.
  def stop
    @keep_watching = false

    after_stop

    nil
  end

  # Calls the update block repeatedly until all changes in the
  # current snapshot are dealt with
  def finalize(&on_update)
    on_update = @on_update unless block_given?

    while file_system_updated?(@end_snapshot || current_snapshot)
      finalizing
      trigger_changes(on_update)
    end

    @end_snapshot = nil
  end

  private

  def expand_directories(patterns)
    patterns = Array(patterns) unless patterns.is_a? Array
    expanded_patterns = patterns.map do |pattern|
      pattern = File.expand_path(pattern)
      Dir[
        File.directory?(pattern) ? File.join(pattern, '**', '*') : pattern
      ]
    end
    expanded_patterns.flatten!
    expanded_patterns.uniq!
    expanded_patterns
  end

  def debug(data)
    @logger.debug "Thread ##{Thread.current.object_id} #{data}"
  end

  def after_initialize(*)
    super if defined?(super)
  end

  def before_pause_sleep
    super if defined?(super)
  end

  def before_resume_sleep
    super if defined?(super)
  end

  def after_stop
    super if defined?(super)
  end

  def finalizing
    super if defined?(super)
  end
end

# Require at end of file to not overwrite `Filewatcher` class
require_relative 'filewatcher/version'
