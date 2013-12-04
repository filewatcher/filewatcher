# Simple file watcher. Detect changes in files and directories.
#
# Issues: Currently doesn't monitor changes in directorynames
class FileWatcher

  def self.VERSION
    return "0.2.1"
  end

  def initialize(filenames,print_filelist=false)
    if(filenames.kind_of?String)
      filenames = [filenames]
    end

    filenames = expand_directories(filenames)

    if(print_filelist)
      if(print_filelist.kind_of?String)
        puts print_filelist
      else
        puts "Watching:"
      end
      filenames.each do |filename|
        puts filename
      end
    end

    @last_mtimes = { }
    filenames.each do |filename|
      raise "File does not exist" unless File.exist?(filename)
      @last_mtimes[filename] = File.stat(filename).mtime
    end
    @filenames = filenames
    @deleted_files = []
  end

  def watch(sleep=1, &on_update)
    loop do
      begin
        Kernel.sleep sleep until file_updated?
      rescue SystemExit,Interrupt
        Kernel.exit
      end
      yield @updated_file, @event
    end
  end

  def file_updated?
    @filenames.each do |filename|

      if(not(@deleted_files.include?(filename)))

        if(not(File.exist?(filename)))
          @deleted_files << filename
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
    end
    return false
  end

  def expand_directories(filenames)
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
