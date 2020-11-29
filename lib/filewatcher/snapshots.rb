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

    # Takes a snapshot of the current status of watched files.
    # (Allows avoidance of potential race condition during #finalize)
    def current_snapshot
      Filewatcher::Snapshot.new(
        expand_directories(@unexpanded_filenames) -
          expand_directories(@unexpanded_excluded_filenames)
      )
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

    def file_system_updated?(snapshot = current_snapshot)
      debug __method__

      @changes = snapshot - @last_snapshot

      @last_snapshot = snapshot

      @changes.any?
    end
  end
end
