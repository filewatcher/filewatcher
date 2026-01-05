# frozen_string_literal: true

require 'forwardable'

class Filewatcher
  # Class for snapshots of file system
  class Snapshot
    extend Forwardable

    def_delegators :@data, :[], :each, :each_key, :keys

    def initialize(filenames)
      @data = filenames.each_with_object({}) do |filename, data|
        data[filename] = SnapshotFile.new(filename)
      end
    end

    def -(other)
      changes = {}

      each do |filename, snapshot_file|
        changes[filename] = snapshot_file - other[filename]
      end

      other.each_key do |filename|
        changes[filename] = :deleted unless self[filename]
      end

      changes.tap(&:compact!)
    end

    # Class for one file from snapshot
    class SnapshotFile
      class << self
        def stats
          @stats ||= populate_stats %i[mtime]
        end

        def populate_stats(stats)
          defined?(super) ? super : stats
        end

        def subtractions
          @subtractions ||= populate_subtractions(
            created: lambda(&:nil?),
            updated: ->(other) { mtime && mtime > other.mtime }
          )
        end

        def populate_subtractions(hash)
          hash = super if defined?(super)
          hash
        end
      end

      attr_reader :mtime

      def initialize(filename)
        @filename = filename
        self.class.stats.each do |stat|
          time = File.public_send(stat, filename) if File.exist?(filename)
          instance_variable_set :"@#{stat}", time || Time.new(0)
        end
      end

      def -(other)
        self.class.subtractions.find do |_event, block|
          instance_exec(other, &block)
        end&.first
      end

      def inspect
        stats_string =
          self.class.stats
            .map { |stat| "#{stat}=#{public_send(stat)&.strftime('%F %T.%9N')&.inspect}" }
            .join(', ')

        <<~OUTPUT
          #<Filewatcher::Snapshot::SnapshotFile:#{object_id}
            @filename=#{@filename.inspect}, #{stats_string}
          >
        OUTPUT
      end
    end

    private_constant :SnapshotFile
  end
end
