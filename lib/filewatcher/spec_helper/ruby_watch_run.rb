# frozen_string_literal: true

require_relative 'watch_run'

class Filewatcher
  module SpecHelper
    ## Ruby API watcher for specs
    class RubyWatchRun
      include WatchRun

      attr_reader :filewatcher, :thread, :watched, :processed

      def initialize(filewatcher:, **args)
        super(**args)
        @filewatcher = filewatcher

        @mutex = Mutex.new
      end

      def start
        super
        @thread = thread_initialize
        # thread needs a chance to start
        wait seconds: 1
        wait do
          keep_watching = filewatcher.keep_watching
          debug "keep_watching = #{keep_watching}"
          keep_watching
        end
      end

      def stop
        thread.exit

        wait do
          thread.stop?
        end

        super
      end

      def wait(seconds: 1)
        super seconds: seconds, interval: filewatcher.interval
      end

      private

      def make_changes
        super

        # Some OS, file systems and Ruby interpretators
        # doesn't catch milliseconds of `File.mtime`
        wait do
          @mutex.synchronize do
            debug "processed = #{processed}"
            debug "processed.any? = #{processed.any?}"
            processed.any?
          end
        end
      end

      def thread_initialize
        @watched ||= 0
        @processed = []
        Thread.new { setup_filewatcher }
      end

      def setup_filewatcher
        debug 'setup_filewatcher'
        debug filewatcher.inspect
        filewatcher.watch do |changes|
          debug filewatcher.inspect
          @mutex.synchronize do
            debug "watch callback: changes = #{changes.inspect}"
            increment_watched
            @processed.push(changes)
            # debug 'pushed to processed'
          end
        end
      end

      def increment_watched
        @watched += 1
      end
    end
  end
end
