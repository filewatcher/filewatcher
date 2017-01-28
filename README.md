# Filewatcher

[![Gem Version](https://badge.fury.io/rb/filewatcher.svg)](http://badge.fury.io/rb/filewatcher)
[![Build Status](https://secure.travis-ci.org/thomasfl/filewatcher.png?branch=master)](http://travis-ci.org/thomasfl/filewatcher)
[![Dependency Status](https://gemnasium.com/thomasfl/filewatcher.png?travis)](https://gemnasium.com/thomasfl/filewatcher)
[![Code Climate](https://codeclimate.com/github/thomasfl/filewatcher.png)](https://codeclimate.com/github/thomasfl/filewatcher)

Lightweight filewatcher weighing less than 200 LoC. No dependencies or platform specific code. Works everywhere. Monitors changes in the filesystem by polling. Has no config files. When running filewatcher from the command line, you specify which files to monitor and what action to perform on updates.

For example to search recursively for javascript files and run jshint when a file is updated, added, renamed or deleted:

Linux/macOS:

```
$ filewatcher '**/*.js' 'jshint $FILENAME'
```

In Windows:

```
> filewatcher "**/*.js" "jshint %FILENAME%"
```

## Install

Needs Ruby and Rubygems:

```
$ [sudo] gem install filewatcher
```

## Command line utility

Filewatcher scans the filesystem and execute shell commands when files are
updated, added, renamed or deleted.

```
Usage:
    filewatcher [<options>] "<filename>" "<shell command>"

Where
    filename: filename(s) to scan.
    shell command: shell command to execute when a file is changed
    options: see below
```

## Examples

Run the echo command when the file myfile is changed:

```
$ filewatcher "myfile" "echo 'myfile has changed'"
```

Run any javascript in the current directory when it is updated in Windows
Powershell:

```
> filewatcher *.js "node %FILENAME%"
```

In Linux/macOS:

```
$ filewatcher *.js 'node $FILENAME'
```

Place filenames or filenames in quotes to use ruby filename globbing instead
of shell filename globbing. This will make filewatcher look for files in
subdirectories too. To watch all javascript files in subdirectories in Windows:

```
> filewatcher "**/*.js" "node %FILENAME%"
```

In Linux/macOS:

```
$ filewatcher '**/*.js' 'node $FILENAME'
```

Try to run the updated file as a script when it is updated by using the
--exec/-e option. Works with files with file extensions that looks like a
python, ruby, perl, php, javascript or awk script.

```
$ filewatcher -e *.rb
```

Print a list of all files matching \*.css first and then output the filename
when a file is beeing updated by using the --list/-l option:

```
$ filewatcher -l '**/*.css' 'echo file: $FILENAME'
```

Watch the "src" and "test" folders recursively, and run test when the
filesystem gets updated:

```
$ filewatcher "src test" "ruby test/test_suite.rb"
```

## Restart long running commands

The `--restart` option kills the command if it's still running when a filesystem change happens. Can be used to restart locally running webservers on updates, or kill long running tests and restart on updates. This option often makes filewatcher faster in general. To not wait for tests to finish:

```
$ filewatcher --restart "**/*.rb" "rake test"
```

The `--dontwait` option starts the command on startup without waiting for filesystem updates. To start a webserver and have it automatically restart when html files are updated:

```
$ filewatcher --restart --dontwait "**/*.html" "python -m SimpleHTTPServer"
```

## Daemonizing filewatcher process

The `--daemon` option starts filewatcher in the background as system daemon, so filewatcher will not be terminated by `Ctrl+C`, for example.

## Available enviroment variables

The environment variable $FILENAME is available in the shell command argument.
On unix like systems the command has to be enclosed in single quotes. To run
node whenever a javascript file is updated:

```
$ filewatcher *.js 'node $FILENAME'
```

Environment variables available from the command string:

```
BASENAME           File basename.
FILENAME           Relative filename.
ABSOLUTE_FILENAME  Asolute filename.
RELATIVE_FILENAME  Same as FILENAME but starts with "./"
EVENT              Event type. Is either 'changed', 'delete' or 'new'.
DIRNAME            Absolute directory name.
```

## Command line options

Useful command line options:

```
        --list, -l:   Print name of matching files on startup
     --restart, -r:   Run command in separate fork and kill it on filesystem updates
    --dontwait, -d:   Run the command before any filesystem updates
      --daemon, -D:   Run in the background as system daemon
     --spinner, -s:   Display an animated spinner while scanning
```

Other command line options:

```
     --version, -v:   Print version and exit
        --help, -h:   Show this message
--interval, -i <f>:   Interval in seconds to scan filesystem, defaults to 0.5 seconds
        --exec, -e:   Execute file as a script when file is updated
 --include, -n <s>:   Include files (default: *)
 --exclude, -x <s>:   Exclude file(s) matching (default: "")
 ```

## Ruby API

Watch a list of files and directories:

```ruby
require 'filewatcher'

FileWatcher.new(['lib/', 'Rakefile']).watch do |filename|
  puts "Changed #{filename}"
end
```

Watch a single directory, for changes in all files and subdirectories:

```ruby
FileWatcher.new('lib/').watch do |filename|
  # ...
end
```

Notice that the previous is equivalent to the following:

```ruby
FileWatcher.new('lib/**/*').watch do |filename|
  # ...
end
```

Watch files and dirs in the given directory - and not in subdirectories:

```ruby
FileWatcher.new('lib/*').watch do |filename|
  # ...
end
```

Watch an absolute directory:

```ruby
FileWatcher.new('/tmp/foo').watch do |filename|
  # ...
end
```

To detect if a file is updated, added or deleted:

```ruby
FileWatcher.new(['README.rdoc']).watch do |filename, event|
  case event
  when :changed
    puts "File updated: #{filename}"
  when :delete
    puts "File deleted: #{filename}"
  when :new
    puts "Added file: #{filename}"
  end
end
```

When a file is renamed it is detected as a new file followed by a file deletion.

The API takes some of the same options as the command line interface. To watch all files recursively except files that matches \*.rb, display a spinner and only wait for 0.1 seconds between each scan:

```ruby
FileWatcher.new('**/*.*', exclude: '**/*.rb', spinner: true, interval: 0.1)
  .watch do |filename|
    puts filename
  end
```

To do the same from the command line, use the same options:

```
$ filewatcher '**/*.*' --exclude '**/*.rb' --spinner --interval 0.1 'echo $FILENAME'
```

Use patterns to match filenames in current directory and subdirectories. The
pattern is not a regular expression; instead it follows rules similar to shell
filename globbing. See Ruby
[documentation](http://www.ruby-doc.org/core-2.1.1/File.html#method-c-fnmatch)
for syntax.

```ruby
FileWatcher.new(['*.rb', '*.xml']).watch do |filename|
  puts "Updated #{filename}"
end
```

Start, pause, resume, stop, and finalize a running watch. This is particularly
useful when the update block takes a while to process each file (eg. sending
over the network)

```ruby
filewatcher = FileWatcher.new(['*.rb'])
thread = Thread.new(filewatcher) { |fw| fw.watch{ |f| puts "Updated #{f}" } }
# ...
filewatcher.pause       # block stops responding to filesystem changes
filewatcher.finalize    # Ensure all filesystem changes made prior to
                        # pausing are handled.
# ...
filewatcher.resume      # block begins responding again, but is not given
                        # changes made between #pause_watch and
                        # #resume_watch
# ...
filewatcher.end         # block stops responding to filesystem changes
                        # and takes a final snapshot of the filesystem
thread.join

filewatcher.finalize    # Ensure all filesystem changes made prior to
                        # ending the watch are handled.
```

If basename, relative filename or absolute filename is necessary use the standard lib 'pathname' like this:

```ruby
require 'pathname'

FileWatcher.new(['**/*.*']).watch do |filename|
  path = Pathname.new(filename)
  puys "Basename         : #{path.basename}"
  puts "Relative filename: #{File.join('.', path)}"
  puts "Absolute filename: #{path.realpath}"
end
```

The filewatcher library is a single file with 180 LOC (including comments)
with no dependencies.

## Changelog

*   0.5.3 Exclude files. More environment variables. Options in ruby api.
*   0.5.2 Start, stop and finalize API.
*   0.5.1 Kill and restart long running command with --restart option.

## Credits

This project would not be where it is today without the generous help provided by people reporting issues and these contributors:

*   [Penn Taylor](https://github.com/penntaylor): Spinner displayed in the terminal and Start, pause, resume, stop, and finalize a running watch.

*   [Franco Leonardo Bulgarelli](https://github.com/flbulgarelli): Support for absolute and globbed paths

*   [Kristoffer Roupé](https://github.com/kitofr): Command line globbing

This gem was initially inspired by [Tom Lieber's blogg posting](http://alltom.com/pages/detecting-file-changes-with-ruby).

## Note on Patches/Pull Requests

*   Fork the project.
*   Make your feature addition or bug fix.
*   Add tests for it. This is important so I don't break it in a future version unintentionally.
*   Commit, do not mess with rakefile, version, or history. (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
*   Send me a pull request. Bonus points for topic branches.


## Copyright

Copyright (c) 2011 - 2017 Thomas Flemming. See LICENSE for details.
