# frozen_string_literal: true

require 'forwardable'

class Filewatcher
  # Class for snapshots of file system
  class Snapshot
    extend Forwardable
    def_delegators :@data, :[], :each, :keys

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

      other.each do |filename, _snapshot_file|
        changes[filename] = :deleted unless self[filename]
      end

      changes.reject! { |_filename, event| event.nil? }
      changes
    end

    # Class for one file from snapshot
    class SnapshotFile
      STATS = %i[mtime].freeze

      attr_reader(*STATS)

      def initialize(filename)
        @filename = filename
        STATS.each do |stat|
          time = File.public_send(stat, filename) if File.exist?(filename)
          instance_variable_set :"@#{stat}", time || Time.new(0)
        end
      end

      def -(other)
        if other.nil?
          :created
        elsif other.mtime < mtime
          :updated
        end
      end

      def inspect
        <<~OUTPUT
          #<Filewatcher::Snapshot::SnapshotFile:#{object_id}
            @filename=#{@filename.inspect}, mtime=#{mtime.strftime('%F %T.%9N').inspect}
          >
        OUTPUT
      end
    end

    private_constant :SnapshotFile
  end
end
