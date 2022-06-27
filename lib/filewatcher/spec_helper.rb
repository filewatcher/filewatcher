# frozen_string_literal: true

require 'logger'

begin
  require 'pry-byebug'
rescue LoadError
  nil
end

require_relative 'spec_helper/watch_run'
require_relative 'spec_helper/ruby_watch_run'

class Filewatcher
  ## Helper for common spec features between plugins
  module SpecHelper
    ENVIRONMENT_SPECS_COEFFICIENTS = {
      -> { ENV.fetch('CI', false) } => 1,
      -> { RUBY_PLATFORM == 'java' } => 1,
      -> { Gem::Platform.local.os == 'darwin' } => 1
    }.freeze

    def logger
      @logger ||= Logger.new($stdout, level: :debug)
    end

    def environment_specs_coefficients
      ENVIRONMENT_SPECS_COEFFICIENTS
    end

    def wait(seconds: 1, interval: 1, &block)
      environment_specs_coefficients.each do |condition, coefficient|
        next unless instance_exec(&condition)

        interval *= coefficient
        seconds *= coefficient
      end

      if block
        wait_with_block seconds, interval, &block
      else
        wait_without_block seconds
      end
    end

    def wait_with_block(seconds, interval, &_block)
      (seconds / interval).ceil.times do
        break if yield

        debug "sleep interval #{interval}"
        sleep interval
      end
    end

    def wait_without_block(seconds)
      debug "sleep without intervals #{seconds}"
      sleep seconds
    end

    def debug(string)
      logger.debug "Thread ##{Thread.current.object_id} #{string}"
    end

    def system_stat(filename)
      case (host_os = RbConfig::CONFIG['host_os'])
      when /linux(-gnu)?/
        `stat --printf 'Modification: %y, Change: %z\n' #{filename}`
      when /darwin\d*/
        `stat #{filename}`
      when *Gem::WIN_PATTERNS
        system_stat_windows filename
      else
        "Unknown OS `#{host_os}` for system's `stat` command"
      end
    end

    def system_stat_windows(filename)
      filename = filename.gsub('/', '\\\\\\')
      properties = 'CreationDate,InstallDate,LastModified,LastAccessed'
      command = "wmic datafile where Name=\"#{filename}\" get #{properties}"
      # debug command
      `#{command}`
    end

    ## https://github.com/rubocop/ruby-style-guide/issues/556#issuecomment-828672008
    # rubocop:disable Style/ModuleFunction
    extend self
    # rubocop:enable Style/ModuleFunction
  end
end
