Filewatcher
===========

[![Gem Version](https://badge.fury.io/rb/filewatcher.svg)](http://badge.fury.io/rb/filewatcher)
[![Build Status](https://secure.travis-ci.org/thomasfl/filewatcher.png?branch=master)](http://travis-ci.org/thomasfl/filewatcher)
[![Dependency Status](https://gemnasium.com/thomasfl/filewatcher.png?travis)](https://gemnasium.com/thomasfl/filewatcher)
[![Code Climate](https://codeclimate.com/github/thomasfl/filewatcher.png)](https://codeclimate.com/github/thomasfl/filewatcher)

Lightweight filewatcher weighing less than 200 LoC. No dependencies or platform specific code.
Works everywhere. Monitors changes in the filesystem by polling. No config files needed to run.
When running filewatcher from the command line, you specify which files to monitor and what action
to perform on updates.

Search recursively for javascript files and run jshint when a file is updated, added,
renamed or deleted:

Linux/OSX:

    $ filewatcher '**/*.js' 'jshint $FILENAME'

In Windows:

    > filewatcher "**/*.js" "jshint %FILENAME%"

Install
-------

Needs Ruby and Rubygems:

    $ [sudo] gem install filewatcher

Command line utility
--------------------

Filewatcher scans the filesystem and execute shell commands when files are
updated, added, renamed or deleted.

    Usage:
        filewatcher [-i interval][-l] "<filename>" "<shell command>"

    Where
        filename: filename(s) to scan.
        shell command: shell command to execute when a file is changed

Examples
--------

Run the echo command when the file myfile is changed:

    $ filewatcher "myfile" "echo 'myfile has changed'"

Run any javascript in the current directory when it is updated in Windows
Powershell:

    > filewatcher *.js "node %FILENAME%"

In Linux/OSX:

    $ filewatcher *.js 'node $FILENAME'

Place filenames or filenames in quotes to use ruby filename globbing instead
of shell filename globbing. This will make filewatcher look for files in
subdirectories too. To watch all javascript files in subdirectories:

    > filewatcher "**/*.js" "node %FILENAME%"

In Linux/OSX:

    > filewatcher '**/*.js' 'node $FILENAME'

Try to run the updated file as a script when it is updated by using the
--exec/-e option. Works with files with file extensions that looks like a
python, ruby, perl, php, javascript or awk script.

    $ filewatcher -e *.rb

Print a list of all files matching *.css first and then output the filename
when a file is beeing updated by using the --list/-l option:

    $ filewatcher -l *.css 'echo file: $FILENAME'

Watch the "src" and "test" folders recursively, and run test when the
filesystem gets updated:

    $ filewatcher "src test" "ruby test/test_suite.rb"

Restart long running commands
-----------------------------

The `--restart` option kills the command if it's still running when a filesystem change happens. Can be used to restart locally running webservers on updates, or kill long running tests and restart on updates. This option often makes filewatcher faster in general. To not wait for tests to finish:

    $ filewatcher --restart "**/*.rb" "rake test"

The `--dontwait` option starts the command on startup without waiting for filesystem updates. To start a webserver and have it automatically restart when html files are updated:

    $ filewatcher --restart --dontwait "*.html" "python -m SimpleHTTPServer"

Available enviroment variables
------------------------------

The environment variable $FILENAME is available in the shell command argument.
On unix like systems the command has to be enclosed in single quotes. To run
node whenever a javascript file is updated:

    $ filewatcher *.js 'node $FILENAME'

The environment variables $FILEPATH, $FILEDIR and $FSEVENT is also available.

Command line options
--------------------

Useful command line options:

            --list, -l:   Print name of files being watched on startup
         --restart, -r:   Kill the command if it's still running
        --dontwait, -d:   Start the command immediately

Other command line options:

         --version, -v:   Print version and exit
            --help, -h:   Show this message
    --interval, -i <f>:   Interval in seconds to scan filesystem. Defaults to 0.5 seconds.
            --exec, -e:   Execute file as a script when file is updated
     --include, -n <s>:   Include files (default: *)
     --exclude, -x <s>:   Exclude file(s) matching (default: "")

Ruby API
--------

Watch a list of files and directories:

    require 'filewatcher'

    FileWatcher.new(["lib/", "Rakefile"]).watch do |filename|
      puts "Changed " + filename
    end

Watch a single directory, for changes in all files and subdirectories:

    FileWatcher.new("lib/").watch do |filename|
      ...
    end

Notice that the previous is equivalent to the following:

    FileWatcher.new("lib/**/*").watch do |filename|
      ...
    end

Watch files and dirs in the given directory - and not in subdirectories:

    FileWatcher.new("lib/*").watch do |filename|
      ...
    end

Watch an absolute directory:

    FileWatcher.new("/tmp/foo").watch do |filename|
      ...
    end

To detect if a file is updated, added or deleted:

    FileWatcher.new(["README.rdoc"]).watch() do |filename, event|
      if(event == :changed)
        puts "File updated: " + filename
      end
      if(event == :delete)
        puts "File deleted: " + filename
      end
      if(event == :new)
        puts "Added file: " + filename
      end
    end

When a file is renamed it is detected as a deletion and a file addition.

To check for changes more often than the default once every second:

    FileWatcher.new(["README.rdoc"]).watch(0.5) do |filename|
      puts "Updated " + filename
    end

Print the names of the files found before watching files and folders:

    FileWatcher.new(["lib/"],true).watch do |filename|
      puts "Updated " + filename
    end
    => Watching files:
    lib/filewatcher.rb

Use patterns to match filenames in current directory and subdirectories. The
pattern is not a regular expression; instead it follows rules similar to shell
filename globbing. See Ruby
[documentation](http://www.ruby-doc.org/core-2.1.1/File.html#method-c-fnmatch)
for syntax.

    FileWatcher.new(["*.rb", "*.xml"]).watch do |filename|
      puts "Updated " + filename
    end

Start, pause, resume, stop, and finalize a running watch. This is particularly
useful when the update block takes a while to process each file (eg. sending
over the network)

    filewatcher = FileWatcher.new(["*.rb"])
    thread = Thread.new(filewatcher){|fw| fw.watch{|f| puts "Updated " + f}}
      ...
    filewatcher.pause       # block stops responding to filesystem changes
    filewatcher.finalize    # Ensure all filesystem changes made prior to
                            # pausing are handled.
      ...
    filewatcher.resume       # block begins responding again, but is not given
                             # changes made between #pause_watch and
                             # #resume_watch
      ...
    filewatcher.end        # block stops responding to filesystem changes
                           # and takes a final snapshot of the filesystem
    thread.join

    filewatcher.finalize   # Ensure all filesystem changes made prior to
                           # ending the watch are handled.

The filewatcher library is just a single file with 147 LOC (including comments)
with no dependencies.


Credits
-------
This project would not be where it is today without the generous help provided by people reporting issues and these contributors:


 * Support for absolute and globbed paths by Franco Leonardo Bulgarelli: https://github.com/flbulgarelli

 * Command line globbing by Kristoffer Roupé https://github.com/kitofr

This gem was initially inspired by Tom Lieber's blogg posting: http://alltom.com/pages/detecting-file-changes-with-ruby

Note on Patches/Pull Requests
-----------------------------

*   Fork the project.
*   Make your feature addition or bug fix.
*   Add tests for it. This is important so I don't break it in a future version unintentionally.
*   Commit, do not mess with rakefile, version, or history. (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
*   Send me a pull request. Bonus points for topic branches.


Copyright
---------

Copyright (c) 2011 - 2015 Thomas Flemming. See LICENSE for details.
