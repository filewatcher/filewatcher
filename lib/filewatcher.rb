# frozen_string_literal: true

require 'logger'
require_relative 'filewatcher/cycles'
require_relative 'filewatcher/snapshots'

# Simple file watcher. Detect changes in files and directories.
#
# Issues: Currently doesn't monitor changes in directorynames
class Filewatcher
  include Filewatcher::Cycles
  include Filewatcher::Snapshots

  attr_accessor :interval
  attr_reader :keep_watching

  def update_spinner(label)
    return unless @show_spinner

    @spinner ||= %w[\\ | / -]
    print "#{' ' * 30}\r#{label}  #{@spinner.rotate!.first}\r"
  end

  def initialize(unexpanded_filenames, options = {})
    @unexpanded_filenames = unexpanded_filenames
    @unexpanded_excluded_filenames = options[:exclude]
    @keep_watching = false
    @pausing = false
    @immediate = options[:immediate]
    @show_spinner = options[:spinner]
    @interval = options.fetch(:interval, 0.5)
    @every = options[:every]
    @logger = options.fetch(:logger, Logger.new($stdout))
  end

  def watch(&on_update)
    ## The set of available signals depends on the OS
    ## Windows doesn't support `HUP` signal, for example
    (%w[HUP INT TERM] & Signal.list.keys).each do |signal|
      trap(signal) { exit }
    end

    @on_update = on_update
    @keep_watching = true
    yield('', '') if @immediate

    main_cycle

    @end_snapshot = current_snapshot
    finalize(&on_update)
  end

  def pause
    @pausing = true
    update_spinner('Initiating pause')
    # Ensure we wait long enough to enter pause loop in #watch
    sleep @interval
  end

  def resume
    raise "Can't resume unless #watch and #pause were first called" if !@keep_watching || !@pausing

    @last_snapshot = current_snapshot # resume with fresh snapshot
    @pausing = false
    update_spinner('Resuming')
    sleep @interval # Wait long enough to exit pause loop in #watch
  end

  # Ends the watch, allowing any remaining changes to be finalized.
  # Used mainly in multi-threaded situations.
  def stop
    @keep_watching = false
    update_spinner('Stopping')
    nil
  end

  # Calls the update block repeatedly until all changes in the
  # current snapshot are dealt with
  def finalize(&on_update)
    on_update = @on_update unless block_given?
    while file_system_updated?(@end_snapshot || current_snapshot)
      update_spinner('Finalizing')
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
end

# Require at end of file to not overwrite `Filewatcher` class
require_relative 'filewatcher/version'
