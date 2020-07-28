# frozen_string_literal: true

require_relative 'snapshot'

# Helpers in Filewatcher class itself
class Filewatcher
  class << self
    def system_stat(filename)
      case Gem::Platform.local.os
      when 'linux' then `stat --printf 'Modification: %y, Change: %z\n' #{filename}`
      when 'darwin' then `stat #{filename}`
      else 'Unknown OS for system `stat`'
      end
    end
  end

  # Module for snapshot logic inside Filewatcher
  module Snapshots
    def found_filenames
      current_snapshot.keys
    end

    private

    def watching_files
      expand_directories(@unexpanded_filenames) - expand_directories(@unexpanded_excluded_filenames)
    end

    # Takes a snapshot of the current status of watched files.
    # (Allows avoidance of potential race condition during #finalize)
    def current_snapshot
      Filewatcher::Snapshot.new(watching_files)
    end

    def file_mtime(filename)
      return Time.new(0) unless File.exist?(filename)

      result = File.mtime(filename)
      if @logger.level <= Logger::DEBUG
        debug "File.mtime = #{result.strftime('%F %T.%9N')}"
        debug "stat #{filename}: #{self.class.system_stat(filename)}"
      end
      result
    end

    def file_system_updated?(snapshot = current_snapshot)
      debug __method__

      @changes = snapshot - @last_snapshot

      @last_snapshot = snapshot

      @changes.any?
    end
  end
end
