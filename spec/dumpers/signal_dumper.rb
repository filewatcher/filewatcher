# frozen_string_literal: true

require_relative '../spec_helper'

signal = ARGV.first
Signal.trap(signal) do
  dump_to_file signal
end

wait seconds: 60
