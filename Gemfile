# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

group :development do
  gem 'gem_toys', '~> 0.14.0'
  gem 'toys', '~> 0.15.3'
end

group :audit do
  gem 'bundler', '~> 2.0'
  gem 'bundler-audit', '~> 0.9.0'
end

group :test do
  gem 'rspec', '~> 3.8'
  gem 'simplecov', '~> 0.22.0'
  gem 'simplecov-cobertura', '~> 2.1'
end

group :lint do
  ## https://github.com/rubocop/rubocop/issues/10147
  gem 'rubocop', '~> 1.61.0'
  gem 'rubocop-performance', '~> 1.20.2'
  gem 'rubocop-rspec', '~> 3.0.3'
end
