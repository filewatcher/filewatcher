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
      while @keep_watching && !filesystem_updated? && !@pausing
        update_spinner('Watching')
        sleep @interval
      end
    end

    def trigger_changes(on_update = @on_update)
      changes = @every ? @changes : @changes.first(1)
      changes.each do |filename, event|
        on_update.call(filename, event)
      end
      @changes.clear
    end
  end
end
