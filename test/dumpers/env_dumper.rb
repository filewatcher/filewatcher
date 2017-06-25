# frozen_string_literal: true

require_relative '../helper'

dump_to_env_file(
  %w[
    FILENAME BASENAME EVENT DIRNAME ABSOLUTE_FILENAME
    RELATIVE_FILENAME
  ].map { |var| ENV[var] }.join(', ')
)
