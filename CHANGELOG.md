# Changelog

## Unreleased

*   Add plugin system.
    Take out [CLI](https://github.com/filewatcher/filewatcher-cli)
    and [spinner](https://github.com/filewatcher/filewatcher-spinner).
*   Remove `:every` option: do it yourself via `changes.first`, if you want.
*   Drop Ruby 2.4 and 2.5 support.
*   Support Ruby 3.0 and 3.1.
*   Switch from `bacon` test framework to RSpec.
    Speed up and improve tests, fix many phantom fails.
*   Update development dependencies.
*   Add `rubocop-rspec` and `rubocop-performance`.
*   Resolve new offenses from RuboCop and its plugins.
*   Switch from Travis CI to Cirrus CI.
*   Add JRuby, Windows and TruffleRuby to CI.
*   Add `bundle-audit` CI task.

## 1.1.1 (2018-09-11)

*   Fix `--restart` option.

## 1.1.0 (2018-09-10)

*   Replace `Trollop` with `Optimist`.

## 1.0.0 (2017-09-24)

*   Add `--every` option.
*   Many refactorings.
*   Tests improvements.

## 0.5.4 (2017-01-27)

*   Add `--daemon` option.
*   Fix issues with the `--restart` option.

## 0.5.3 (2015-11-25)

*   Exclude files.
*   More environment variables.
*   Options in Ruby API.

## 0.5.2 (2015-06-21)

*   Start, stop and finalize API.

## 0.5.1 (2015-05-26)

*   Kill and restart long running command with `--restart` option.
