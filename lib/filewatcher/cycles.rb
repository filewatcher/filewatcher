# frozen_string_literal: true

class Filewatcher
  # Module for all cycles in `Filewatcher#watch`
  module Cycles
    private

    def main_cycle
      while @keep_watching
        @end_snapshot = mtime_snapshot if @pausing

        pausing_cycle

        watching_cycle

        # test and clear @changes to prevent yielding the last
        # changes twice if @keep_watching has just been set to false
        trigger_changes
      end
    end

    def pausing_cycle
      while @keep_watching && @pausing
        update_spinner('Pausing')
        sleep @interval
      end
    end

    def watching_cycle
      @logger.debug __method__
      @last_snapshot ||= mtime_snapshot
      loop do
        update_spinner('Watching')
        @logger.debug "#{__method__} sleep #{@interval}"
        sleep @interval
        break if !@keep_watching || file_system_updated? || @pausing
      end
    end

    def trigger_changes(on_update = @on_update)
      @logger.debug __method__
      changes = @every ? @changes : @changes.first(1)
      changes.each do |filename, event|
        on_update.call(filename, event)
      end
      @changes.clear
      @logger.debug '@changes cleared'
    end
  end
end
