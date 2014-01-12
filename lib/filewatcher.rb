# Simple file watcher. Detect changes in files and directories.
#
# Issues: Currently doesn't monitor changes in directorynames
class FileWatcher

  def self.VERSION
    return "0.3.2"
  end

  def initialize(unexpanded_filenames, print_filelist=false)
    @unexpanded_filenames = unexpanded_filenames
    @last_mtimes = { }
    @filenames = expand_directories(@unexpanded_filenames)

    puts "Watching:" if print_filelist
    @filenames.each do |filename|
      raise "File does not exist" unless File.exist?(filename)
      @last_mtimes[filename] = File.stat(filename).mtime
      puts filename if print_filelist
    end
  end

  def watch(sleep=1, &on_update)
    loop do
      begin
        Kernel.sleep sleep until filesystem_updated?
      rescue SystemExit,Interrupt
        Kernel.exit
      end
      yield @updated_file, @event
    end
  end

  def filesystem_updated?
    filenames = expand_directories(@unexpanded_filenames)

    if(filenames.size > @filenames.size)
      filename = (filenames - @filenames).first
      @filenames << filename
      @last_mtimes[filename] = File.stat(filename).mtime
      @updated_file = filename
      @event = :new
      return true
    end

    if(filenames.size < @filenames.size)
      filename = (@filenames - filenames).first
      @filenames.delete(filename)
      @last_mtimes.delete(filename)
      @updated_file = filename
      @event = :delete
      return true
    end

    @filenames.each do |filename|
      if(not(File.exists?(filename)))
        @filenames.delete(filename)
        @last_mtimes.delete(filename)
        @updated_file = filename
        @event = :delete
        return true
      end
      mtime = File.stat(filename).mtime
      updated = @last_mtimes[filename] < mtime
      @last_mtimes[filename] = mtime
      if(updated)
        @updated_file = filename
        @event = :changed
        return true
      end
    end

    return false
  end

  def expand_directories(filenames)
    if(filenames.kind_of?String)
      filenames = [filenames]
    end
    files = []
    filenames.each do |filename|
      if(File.directory?(filename))
        files = files + find(filename)
      end
      if(File.file?(filename))
        files << filename
      end
    end
    filenames = files
  end

  def find(dir, filename="*.*", subdirs=true)
    Dir[ subdirs ? File.join(dir.split(/\\/), "**", filename) : File.join(dir.split(/\\/), filename) ]
  end

end
