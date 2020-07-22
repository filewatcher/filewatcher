# frozen_string_literal: true

class Filewatcher
  # Module for snapshot logic inside Filewatcher
  module Snapshots
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
        snapshot[filename] = file_mtime(filename)
      end
      snapshot
    end

    def file_mtime(filename)
      return Time.new(0) unless File.exist?(filename)

      result = File.mtime(filename)
      @logger.debug "File.mtime = #{result}"
      @logger.debug "stat #{filename}:"
      system "stat #{filename}"
      result
    end

    def filesystem_updated?(snapshot = mtime_snapshot)
      @changes = {}

      (snapshot.to_a - last_snapshot.to_a).each do |file, _mtime|
        @changes[file] = last_snapshot[file] ? :updated : :created
      end

      (last_snapshot.keys - snapshot.keys).each do |file|
        @changes[file] = :deleted
      end

      @last_snapshot = snapshot
      @changes.any?
    end
  end
end
