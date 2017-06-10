# frozen_string_literal: true

require 'pathname'
require_relative '../filewatcher'

class Filewatcher
  # Class for building ENV variables for executable
  class Env
    def initialize(filename, event)
      @filename = filename
      @event = event
      @path = Pathname.new(@filename)
      @realpath = @path.realpath
      @current_dir = Pathname.new(Dir.pwd)
    end

    def to_h
      {
        'FILEPATH' => (@realpath.to_s if @event != :deleted),
        'FILENAME' => @filename,
        'BASENAME' => @path.basename.to_s,
        'EVENT' => @event.to_s,
        'DIRNAME' => @path.parent.realpath.to_s,
        'ABSOLUTE_FILENAME' => @realpath.to_s,
        'RELATIVE_FILENAME' => @realpath.relative_path_from(@current_dir).to_s
      }
    end
  end
end
