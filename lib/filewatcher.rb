# frozen_string_literal: true

require_relative 'filewatcher/cycles'

# Simple file watcher. Detect changes in files and directories.
#
# Issues: Currently doesn't monitor changes in directorynames
class Filewatcher
  include Filewatcher::Cycles

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
  end

  def watch(&on_update)
    ## The set of available signals depends on the OS
    ## Windows doesn't support `HUP` signal, for example
    (%w[HUP INT TERM] & Signal.list.keys).each { |signal| trap(signal) { exit } }
    @on_update = on_update
    @keep_watching = true
    yield('', '') if @immediate

    main_cycle

    @end_snapshot = mtime_snapshot
    finalize(&on_update)
  end

  def pause
    @pausing = true
    update_spinner('Initiating pause')
    # Ensure we wait long enough to enter pause loop in #watch
    sleep @interval
  end

  def resume
    if !@keep_watching || !@pausing
      raise "Can't resume unless #watch and #pause were first called"
    end
    @last_snapshot = mtime_snapshot # resume with fresh snapshot
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
    while filesystem_updated?(@end_snapshot || mtime_snapshot)
      update_spinner('Finalizing')
      trigger_changes(on_update)
    end
    @end_snapshot = nil
  end

  def last_found_filenames
    last_snapshot.keys
  end

  private

  def last_snapshot
    @last_snapshot ||= mtime_snapshot
  end

  # Takes a snapshot of the current status of watched files.
  # (Allows avoidance of potential race condition during #finalize)
  def mtime_snapshot
    snapshot = {}
    filenames = expand_directories(@unexpanded_filenames)

    # Remove files in the exclude filenames list
    filenames -= expand_directories(@unexpanded_excluded_filenames)

    filenames.each do |filename|
      mtime = File.exist?(filename) ? File.mtime(filename) : Time.new(0)
      snapshot[filename] = mtime
    end
    snapshot
  end

  def filesystem_updated?(snapshot = mtime_snapshot)
    @changes = {}

    # rubocop:disable Perfomance/HashEachMethods
    ## https://github.com/bbatsov/rubocop/issues/4732
    (snapshot.to_a - last_snapshot.to_a).each do |file, _mtime|
      @changes[file] = last_snapshot[file] ? :updated : :created
    end

    (last_snapshot.keys - snapshot.keys).each do |file|
      @changes[file] = :deleted
    end

    @last_snapshot = snapshot
    @changes.any?
  end

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
end

# Require at end of file to not overwrite `Filewatcher` class
require_relative 'filewatcher/version'
