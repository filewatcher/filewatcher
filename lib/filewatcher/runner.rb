# frozen_string_literal: true

class Filewatcher
  ## Get runner command by filename
  class Runner
    ## Define runners for `--exec` option
    RUNNERS = {
      python: %w[py],
      node:   %w[js],
      ruby:   %w[rb],
      perl:   %w[pl],
      awk:    %w[awk],
      php:    %w[php phtml php4 php3 php5 phps]
    }.freeze

    def initialize(filename)
      @filename = filename
      @ext = File.extname(filename).delete('.')
    end

    def command
      "env #{runner} #{@filename}" if runner
    end

    private

    def runner
      return @runner if defined?(@runner)
      @runner, _exts = RUNNERS.find { |_cmd, exts| exts.include? @ext }
      @runner
    end
  end
end
