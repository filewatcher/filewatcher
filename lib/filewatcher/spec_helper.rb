# frozen_string_literal: true

require 'logger'

begin
  require 'pry-byebug'
rescue LoadError
  nil
end

require_relative 'spec_helper/watch_run'

class Filewatcher
  ## Helper for common spec features between plugins
  module SpecHelper
    module_function

    def logger
      @logger ||= Logger.new($stdout, level: :debug)
    end

    def environment_specs_coefficients
      @environment_specs_coefficients ||= {
        -> { ENV['CI'] } => 1,
        -> { RUBY_PLATFORM == 'java' } => 3,
        -> { Gem::Platform.local.os == 'darwin' } => 1
      }
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
  end
end
