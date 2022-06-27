# frozen_string_literal: true

class Filewatcher
  module SpecHelper
    ## Base class for Filewatcher runners in specs
    class WatchRun
      include Filewatcher::SpecHelper

      TMP_DIR = "#{Dir.getwd}/spec/tmp"

      attr_reader :filename

      def initialize(filename:, action:, directory:)
        @filename = filename.match?(%r{^(/|~|[A-Z]:)}) ? filename : File.join(TMP_DIR, filename)
        @directory = directory
        @action = action
        debug "action = #{action}"
      end

      def start
        debug 'start'
        File.write(@filename, 'content1') unless @action == :create

        wait seconds: 1
      end

      def run(make_changes_times: 1)
        start

        make_changes_times.times do
          make_changes

          wait seconds: 2
        end

        stop
      end

      def stop
        debug 'stop'
        FileUtils.rm_r(@filename) if File.exist?(@filename)
      end

      private

      def make_changes
        debug "make changes, @action = #{@action}, @filename = #{@filename}"

        if @action == :delete
          FileUtils.remove(@filename)
        elsif @directory
          FileUtils.mkdir_p(@filename)
        elsif %i[create update].include? @action
          ## There is no `File.write` because of strange difference in parallel `File.mtime`
          ## https://cirrus-ci.com/task/6107605053472768?command=test#L497-L511
          system "echo 'content2' > #{@filename}"
          debug_file_mtime
        else
          raise "Unknown action `#{@action}`"
        end

        wait seconds: 1
      end

      def debug_file_mtime
        debug "stat #{@filename}: #{system_stat(@filename)}"
        debug "File.mtime = #{File.mtime(@filename).strftime('%F %T.%9N')}"
      end
    end
  end
end
