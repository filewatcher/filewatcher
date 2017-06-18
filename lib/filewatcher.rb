# frozen_string_literal: true

require_relative 'filewatcher/cycles'
require_relative 'filewatcher/snapshot'

# Simple file watcher. Detect changes in files and directories.
#
# Issues: Currently doesn't monitor changes in directorynames
class Filewatcher
  include Filewatcher::Cycles

  attr_writer :interval

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
    @access = options[:access]
    @show_spinner = options[:spinner]
    @interval = options.fetch(:interval, 0.5)
  end

  def watch(&on_update)
    trap('SIGINT') { return }
    @on_update = on_update
    @keep_watching = true
    yield({}) if @immediate

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
    if !@keep_watching || !@pausing
      raise "Can't resume unless #watch and #pause were first called"
    end
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
    while filesystem_updated?(@end_snapshot || current_snapshot)
      update_spinner('Finalizing')
      on_update.call(@changes)
    end
    @end_snapshot = nil
  end

  def last_found_filenames
    last_snapshot.keys
  end

  private

  def last_snapshot
    @last_snapshot ||= current_snapshot
  end

  def watching_files
    expand_directories(@unexpanded_filenames) -
      expand_directories(@unexpanded_excluded_filenames)
  end

  # Takes a snapshot of the current status of watched files.
  # (Allows avoidance of potential race condition during #finalize)
  def current_snapshot
    Filewatcher::Snapshot.new(watching_files)
  end

  def filesystem_updated?(snapshot = current_snapshot)
    @changes = snapshot - last_snapshot

    @last_snapshot = snapshot

    @changes.reject! { |_filename, event| event == :readed } unless @access

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
