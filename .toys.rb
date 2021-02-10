# frozen_string_literal: true

include :bundler, static: true

require 'gem_toys'
expand GemToys::Template

alias_tool :g, :gem
