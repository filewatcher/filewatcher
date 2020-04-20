# frozen_string_literal: true

class Filewatcher
  # Module for all cycles in `Filewatcher#watch`
  module Cycles
    private

    def main_cycle
      while @keep_watching
        @end_snapshot = current_snapshot if @pausing

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
      @last_snapshot ||= current_snapshot
      loop do
        update_spinner('Watching')
        debug "#{__method__} sleep #{@interval}"
        sleep @interval
        break if !@keep_watching || file_system_updated? || @pausing
      end
    end

    def trigger_changes(on_update = @on_update)
      debug __method__
      on_update.call(@changes.dup) unless @changes.empty?
      @changes.clear
      debug '@changes cleared'
    end
  end
end
