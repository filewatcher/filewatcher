# Simple file watcher. Detect changes in files and directories.
#
# Issues: Currently doesn't monitor changes in directorynames
class FileWatcher

  attr_accessor :filenames

  def self.VERSION
    return '0.4.0'
  end

  def initialize(unexpanded_filenames, print_filelist=false, dontwait=false)
    @unexpanded_filenames = unexpanded_filenames
    @filenames = nil
    @stored_update = nil
    @keep_watching = false
    @last_snapshot = mtime_snapshot
    @dontwait = dontwait
    puts 'Watching:' if print_filelist
    @filenames.each do |filename|
      raise 'File does not exist' unless File.exist?(filename)
      puts filename if print_filelist
    end
  end

  def watch(sleep=1, &on_update)
    @stored_update = on_update
    @keep_watching = true
    if(@dontwait)
      yield '',''
    end
    while @keep_watching
      while @keep_watching && not(filesystem_updated?)
        Kernel.sleep sleep
      end
      # test and null @updated_file to prevent yielding the last
      # file twice if @keep_watching has just been set to false
      yield @updated_file, @event if @updated_file
      @updated_file = nil
    end
    finalize(&on_update)
  end

  # Stops the watch, allowing any remaining changes to be finalized.
  # Used mainly in multi-threaded situations.
  def end_watch
    @keep_watching = false
    return nil
  end

  # Calls the update block repeatedly until all changes in the
  # current snapshot are dealt with
  def finalize(&on_update)
    on_update = @stored_update if not block_given?
    snapshot = mtime_snapshot
    while filesystem_updated?(snapshot)
      on_update.call(@updated_file, @event)
    end
    return nil
  end

  # Takes a snapshot of the current status of watched files.
  # (Allows avoidance of potential race condition during #finalize)
  def mtime_snapshot
    snapshot = {}
    @filenames = expand_directories(@unexpanded_filenames)
    @filenames.each do |filename|
      mtime = File.exist?(filename) ? File.stat(filename).mtime : Time.new(0)
      snapshot[filename] = mtime
    end
    return snapshot
  end

  def filesystem_updated?(snapshot_to_use = nil)
    snapshot = snapshot_to_use ? snapshot_to_use : mtime_snapshot

    forward_changes = snapshot.to_a - @last_snapshot.to_a

    forward_changes.each do |file,mtime|
      @updated_file = file
      unless @last_snapshot.fetch(@updated_file,false)
        @last_snapshot[file] = mtime
        @event = :new
        return true
      else
        @last_snapshot[file] = mtime
        @event = :changed
        return true
      end
    end

    backward_changes = @last_snapshot.to_a - snapshot.to_a
    forward_names = forward_changes.map{|change| change.first}
    backward_changes.reject!{|f,m| forward_names.include?(f)}
    backward_changes.each do |file,mtime|
      @updated_file = file
      @last_snapshot.delete(file)
      @event = :delete
      return true
    end
    return false
  end

  def expand_directories(patterns)
    if(!patterns.kind_of?Array)
      patterns = [patterns]
    end

    patterns.map { |it| Dir[fulldepth(it)] }.flatten.uniq
  end

  private

  def fulldepth(pattern)
    if File.directory? pattern
      "#{pattern}/**/*"
    else
      pattern
    end
  end


end
