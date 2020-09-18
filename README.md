# Filewatcher

[![Gem Version](https://img.shields.io/gem/v/filewatcher?style=flat-square)](https://rubygems.org/gems/filewatcher)
[![Build Status](https://img.shields.io/cirrus/github/filewatcher/filewatcher?style=flat-square)](https://cirrus-ci.com/github/filewatcher/filewatcher)
[![Codecov](https://img.shields.io/codecov/c/gh/filewatcher/filewatcher?style=flat-square)](https://codecov.io/gh/filewatcher/filewatcher)
[![Depfu](https://img.shields.io/depfu/filewatcher/filewatcher?style=flat-square)](https://depfu.com/github/filewatcher/filewatcher)
[![Code Climate](https://img.shields.io/codeclimate/maintainability/filewatcher/filewatcher?style=flat-square)](https://codeclimate.com/github/filewatcher/filewatcher)
[![License](https://img.shields.io/github/license/filewatcher/filewatcher.svg?style=flat-square)](https://github.com/filewatcher/filewatcher/blob/master/LICENSE)

Lightweight file watcher weighing about 300 LOC.
No runtime dependencies and no platform specific code.
Works everywhere.
Monitors changes in the file system by polling.
Has no config files.

## Installation

```bash
$ gem install filewatcher
```

or with `bundler`:

```ruby
# Gemfile
gem 'filewatcher'
```

## Usage

Watch a list of files and directories:

```ruby
require 'filewatcher'

Filewatcher.new(['lib/', 'Rakefile']).watch do |filename, event|
  puts "#{filename} #{event}"
end
```

Watch a single directory, for changes in all files and subdirectories:

```ruby
Filewatcher.new('lib/').watch do |filename, event|
  # ...
end
```

Notice that the previous is equivalent to the following:

```ruby
Filewatcher.new('lib/**/*').watch do |filename, event|
  # ...
end
```

Watch files and directories in the given directory - and not in subdirectories:

```ruby
Filewatcher.new('lib/*').watch do |filename, event|
  # ...
end
```

Watch an absolute directory:

```ruby
Filewatcher.new('/tmp/foo').watch do |filename, event|
  # ...
end
```

To detect if a file is updated, added or deleted:

```ruby
Filewatcher.new(['README.rdoc']).watch do |filename, event|
  puts "File #{event}: #{filename}"
end
```

When a file is renamed and `every` option is enabled, it is detected as
a new file followed by a file deletion:

```ruby
Filewatcher.new(['lib/'], every: true).watch do |filename, event|
  puts "File #{event}: #{filename}"
end

# Rename from `old_test.rb` to `new_test.rb` will print:

# File created: /absolute/path/lib/new_test.rb
# File deleted: /absolute/path/lib/old_test.rb
```

The API takes some of the same options as the command line interface.
To watch all files recursively except files that matches \*.rb
and only wait for 0.1 seconds between each scan:

```ruby
Filewatcher.new('**/*.*', exclude: '**/*.rb', interval: 0.1)
  .watch do |filename, event|
    puts filename
  end
```

Use patterns to match filenames in current directory and subdirectories.
The pattern is not a regular expression;
instead it follows rules similar to shell filename globbing.
See Ruby [documentation](http://www.ruby-doc.org/core-2.1.1/File.html#method-c-fnmatch) for syntax.

```ruby
Filewatcher.new(['*.rb', '*.xml']).watch do |filename|
  puts "Updated #{filename}"
end
```

Start, pause, resume, stop, and finalize a running watch.
This is particularly useful when the update block takes a while to process each file
(e.g. sending over the network).

```ruby
filewatcher = Filewatcher.new(['*.rb'])
thread = Thread.new(filewatcher) { |fw| fw.watch{ |f| puts "Updated #{f}" } }
# ...
filewatcher.pause       # block stops responding to file system changes
filewatcher.finalize    # Ensure all file system changes made prior to
                        # pausing are handled.
# ...
filewatcher.resume      # block begins responding again, but is not given
                        # changes made between #pause_watch and
                        # #resume_watch
# ...
filewatcher.end         # block stops responding to file system changes
                        # and takes a final snapshot of the file system
thread.join

filewatcher.finalize    # Ensure all file system changes made prior to
                        # ending the watch are handled.
```

If basename, relative filename or absolute filename is necessary
use the standard [`pathname`](https://ruby-doc.org/stdlib/libdoc/pathname/rdoc/Pathname.html)
like this:

```ruby
require 'pathname'

Filewatcher.new(['**/*.*']).watch do |filename, event|
  path = Pathname.new(filename)
  puts "Basename         : #{path.basename}"
  puts "Relative filename: #{File.join('.', path)}"
  puts "Absolute filename: #{path.realpath}"
end
```

### Plugins

You can require plugins for Filewatcher, which extends core functionality.

Example:

```ruby
require 'filewatcher'
require 'filewatcher-spinner'

# With the `true` value of option there will be an ASCII spinner in the STDOUT while waiting changes
Filewatcher.new('lib/', spinner: true).watch do |filename, event|
  puts "#{filename} #{event}"
end
```

Available methods are:

*   `#after_initialize`
*   `#before_pause_sleep`
*   `#before_resume_sleep`
*   `#after_stop`
*   `#finalizing`

If you have questions, problems or suggestions about plugins system — please,
don't hesitate to [create a new issue](https://github.com/filewatcher/filewatcher/issues/new).

Official plugins:

*   [CLI](https://github.com/filewatcher/filewatcher-cli)
*   [Spinner](https://github.com/filewatcher/filewatcher-spinner)

## Changelog

Changelog can be found in [an adjacent file](CHANGELOG.md).

## Credits

This project would not be where it is today without the generous help provided by people reporting issues and these contributors:

*   [Thomas Flemming](https://github.com/thomasfl): Original author. Restart option. Exported variables.

*   [Penn Taylor](https://github.com/penntaylor): Spinner displayed in the terminal and Start, pause, resume, stop, and finalize a running watch.

*   [Franco Leonardo Bulgarelli](https://github.com/flbulgarelli): Support for absolute and globbed paths.

*   [Kristoffer Roupé](https://github.com/kitofr): Command line globbing.

*   [Alexander Popov](https://github.com/AlexWayfer): Plugin system, daemon mode (CLI), tests improvements, code style improvements, many other fixes and improvements.

This gem was initially inspired by [Tom Lieber's blog posting](http://alltom.com/pages/detecting-file-changes-with-ruby) ([Web Archive version](http://web.archive.org/web/20120208094934/http://alltom.com/pages/detecting-file-changes-with-ruby)).

## Note on Patches/Pull Requests

*   Fork the project.
*   Make your feature addition or bug fix.
*   Add tests for it. This is important so I don't break it in a future version unintentionally.
*   Commit, do not mess with rakefile, version, or history. (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
*   Send me a pull request. Bonus points for topic branches.


## Copyright

Copyright (c) 2010 - 2018 Thomas Flemming. See LICENSE for details.
