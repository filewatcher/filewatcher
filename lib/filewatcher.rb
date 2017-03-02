# coding: utf-8
# Simple file watcher. Detect changes in files and directories.
#
# Issues: Currently doesn't monitor changes in directorynames
class FileWatcher
  attr_accessor :filenames

  VERSION = '0.5.4'.freeze

  def update_spinner(label)
    return unless @show_spinner
    @spinner ||= %w(\\ | / -)
    print "#{' ' * 30}\r#{label}  #{@spinner.rotate!.first}\r"
  end

  def initialize(unexpanded_filenames, options = {})
    @unexpanded_filenames = unexpanded_filenames
    @unexpanded_excluded_filenames = options[:exclude]
    @keep_watching = false
    @pausing = false
    @last_snapshot = mtime_snapshot
    @immediate = options[:immediate]
    @show_spinner = options[:spinner]
    @interval = options[:interval]
    @delay = options[:delay].to_f
  end

  def watch(sleep = 0.5, &on_update)
    trap('SIGINT') { return }
    @sleep = sleep
    @sleep = @interval if @interval && @interval > 0
    @stored_update = on_update
    @keep_watching = true
    yield({ '' => '' }) if @immediate
    while @keep_watching
      @end_snapshot = mtime_snapshot if @pausing
      while @keep_watching && @pausing
        update_spinner('Pausing')
        Kernel.sleep @sleep
      end
      while @keep_watching && !filesystem_updated? && !@pausing
        update_spinner('Watching')
        Kernel.sleep @sleep
      end
      # test and clear @changes to prevent yielding the last
      # changes twice if @keep_watching has just been set to false
      thread = Thread.new do
        yield @changes if @changes.any?
        @changes.clear
      end
      Kernel.sleep @delay if @delay > 0
      thread.join
    end
    @end_snapshot = mtime_snapshot
    finalize(&on_update)
  end

  def pause
    @pausing = true
    update_spinner('Initiating pause')
    # Ensure we wait long enough to enter pause loop in #watch
    Kernel.sleep @sleep
  end

  def resume
    if !@keep_watching || !@pausing
      raise "Can't resume unless #watch and #pause were first called"
    end
    @last_snapshot = mtime_snapshot # resume with fresh snapshot
    @pausing = false
    update_spinner('Resuming')
    Kernel.sleep @sleep # Wait long enough to exit pause loop in #watch
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
    on_update = @stored_update unless block_given?
    snapshot = @end_snapshot ? @end_snapshot : mtime_snapshot
    while filesystem_updated?(snapshot)
      update_spinner('Finalizing')
      on_update.call(@changes)
    end
    @end_snapshot = nil
  end

  # Takes a snapshot of the current status of watched files.
  # (Allows avoidance of potential race condition during #finalize)
  def mtime_snapshot
    snapshot = {}
    @filenames = expand_directories(@unexpanded_filenames)

    if !@unexpanded_excluded_filenames.nil? &&
       !@unexpanded_excluded_filenames.empty?
      # Remove files in the exclude filenames list
      @filtered_filenames = []
      @excluded_filenames = expand_directories(@unexpanded_excluded_filenames)
      @filenames.each do |filename|
        unless @excluded_filenames.include?(filename)
          @filtered_filenames << filename
        end
      end
      @filenames = @filtered_filenames
    end

    @filenames.each do |filename|
      mtime = File.exist?(filename) ? File.stat(filename).mtime : Time.new(0)
      snapshot[filename] = mtime
    end
    snapshot
  end

  def filesystem_updated?(snapshot_to_use = nil)
    snapshot = snapshot_to_use || mtime_snapshot
    forward_changes = snapshot.to_a - @last_snapshot.to_a
    @changes = {}

    forward_changes.each do |file, mtime|
      event = @last_snapshot.fetch(file, false) ? :updated : :created
      @changes[file] = event
      @last_snapshot[file] = mtime
    end

    backward_changes = @last_snapshot.to_a - snapshot.to_a
    forward_names = forward_changes.map(&:first)
    backward_changes.reject! { |f, _m| forward_names.include?(f) }
    backward_changes.each do |file, _mtime|
      @changes[file] = :deleted
      @last_snapshot.delete(file)
    end
    @changes.any?
  end

  def last_found_filenames
    @last_snapshot.keys
  end

  def expand_directories(patterns)
    patterns = [patterns] unless patterns.is_a? Array
    patterns.map { |it| Dir[fulldepth(expand_path(it))] }.flatten.uniq
  end

  private

  def fulldepth(pattern)
    if File.directory? pattern
      "#{pattern}/**/*"
    else
      pattern
    end
  end

  def expand_path(pattern)
    if pattern.start_with?('~')
      File.expand_path(pattern)
    else
      pattern
    end
  end
end
