# Simple file watcher. Detect changes in files and directories.
#
# Issues: Currently doesn't monitor changes in directorynames
class FileWatcher

  attr_accessor :filenames

  def self.VERSION
    return '0.4.0'
  end

  def update_spinner(label)
    return nil unless @show_spinner
    @spinner ||= %w(\\ | / -)
    print "#{' ' * 30}\r#{label}  #{@spinner.rotate!.first}\r"
  end

  def initialize(unexpanded_filenames, print_filelist=false, dontwait=false, show_spinner=false)
    @unexpanded_filenames = unexpanded_filenames
    @filenames = nil
    @stored_update = nil
    @keep_watching = false
    @pausing = false
    @last_snapshot = mtime_snapshot
    @end_snapshot = nil
    @dontwait = dontwait
    @show_spinner = show_spinner
    puts 'Watching:' if print_filelist
    @filenames.each do |filename|
      raise 'File does not exist' unless File.exist?(filename)
      puts filename if print_filelist
    end
  end

  def watch(sleep=1, &on_update)
    @sleep = sleep
    @stored_update = on_update
    @keep_watching = true
    if(@dontwait)
      yield '',''
    end
    while @keep_watching
      @end_snapshot = mtime_snapshot if @pausing
      while @keep_watching && @pausing
        update_spinner('Pausing')
        Kernel.sleep sleep
      end
      while @keep_watching && !filesystem_updated? && !@pausing
        update_spinner('Scanning')
        Kernel.sleep sleep
      end
      # test and null @updated_file to prevent yielding the last
      # file twice if @keep_watching has just been set to false
      yield @updated_file, @event if @updated_file
      @updated_file = nil
    end
    @end_snapshot = mtime_snapshot
    finalize(&on_update)
  end

  def pause
    @pausing = true
    update_spinner('Initiating pause')
    Kernel.sleep @sleep # Ensure we wait long enough to enter pause loop
                        # in #watch
  end

  def resume
    if !@keep_watching || !@pausing
      raise "Can't resume unless #watch and #pause were first called"
    end
    @last_snapshot = mtime_snapshot  # resume with fresh snapshot
    @pausing = false
    update_spinner('Resuming')
    Kernel.sleep @sleep # Wait long enough to exit pause loop in #watch
  end

  # Ends the watch, allowing any remaining changes to be finalized.
  # Used mainly in multi-threaded situations.
  def stop
    @keep_watching = false
    return nil
  end

  # Calls the update block repeatedly until all changes in the
  # current snapshot are dealt with
  def finalize(&on_update)
    on_update = @stored_update if !block_given?
    snapshot = @end_snapshot ? @end_snapshot : mtime_snapshot
    while filesystem_updated?(snapshot)
      update_spinner('Finalizing')
      on_update.call(@updated_file, @event)
    end
    @end_snapshot =nil
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
