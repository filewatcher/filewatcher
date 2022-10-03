# frozen_string_literal: true

require 'module_methods'

class Filewatcher
  module SpecHelper
    ## Base module for Filewatcher runners in specs
    module WatchRun
      extend ::ModuleMethods::Extension

      include Filewatcher::SpecHelper

      TMP_DIR = "#{Dir.getwd}/spec/tmp"

      attr_reader :initial_files

      ## Class methods for this and inherited modules
      module ClassMethods
        def transform_spec_files(file)
          file.match?(%r{^(/|~|[A-Z]:)}) ? file : File.join(TMP_DIR, file)
        end
      end

      def initialize(initial_files:, changes:)
        @initial_files = initial_files.transform_keys { |key| self.class.transform_spec_files(key) }

        @changes = changes

        debug "changes = #{@changes}"
      end

      def start
        debug 'start'
        initial_files.each do |initial_file_path, initial_file_data|
          File.write(
            File.expand_path(initial_file_path),
            initial_file_data.fetch(:content, 'content1')
          )
        end

        debug "start initial_files = #{initial_files}"

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
        FileUtils.rm_r(self.class::TMP_DIR) if File.exist?(self.class::TMP_DIR)
      end

      private

      create_update_action = lambda do |change_file, change_data|
        new_content = change_data.fetch(:content, 'content2')

        FileUtils.mkdir_p File.dirname(change_file)

        ## There is no `File.write` because of strange difference in parallel `File.mtime`
        ## https://cirrus-ci.com/task/6107605053472768?command=test#L497-L511
        system "echo '#{new_content}' > #{change_file}"

        debug_file_mtime(change_file)
      end.freeze

      CHANGES = {
        create: create_update_action,
        update: create_update_action,
        create_dir: ->(change_file, *_args) { FileUtils.mkdir_p(change_file) },
        delete: ->(change_file, *_args) { FileUtils.remove(change_file) }
      }.freeze

      def make_changes
        @changes.each do |change_file, change_data|
          debug "make changes, change_file = #{change_file}, change_data = #{change_data}"

          change_event = change_data.fetch(:event, :update)
          change_event = :create_dir if change_event == :create && change_data[:directory]

          change_block =
            self.class::CHANGES.fetch(change_event) { raise "Unknown change `#{change_event}`" }

          instance_exec(change_file, change_data, &change_block)
        end

        wait seconds: 1
      end

      def debug_file_mtime(file)
        file = File.expand_path file
        debug "stat #{file}: #{system_stat(file)}"
        debug "File.mtime = #{File.mtime(file).strftime('%F %T.%9N')}"
      end
    end
  end
end
