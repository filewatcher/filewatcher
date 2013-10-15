$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '.'))
require 'helper'

class TestFilewatcher < Test::Unit::TestCase

  should "should detect directories and extract filenames" do

    FileWatcher.new(["test/"],"Watching files. Ctrl-C to abort.").watch(0.1) do |filename|
      puts "updated: " + filename
    end

    FileWatcher.new(["./test/", "Rakefile", "lib"]).watch(0.1) do |filename|
      puts "updated: " + filename
    end

  end

  should "return version number" do
    assert FileWatcher.VERSION.size > 2
  end

#   should "should detect changes in files" do

#     @pid = fork do

#       trap("SIGINT") do
#         exit
#       end

#       FileWatcher.new(["test/helper.rb"]).watch(0.1) do |filename|
#         puts "updated: " + filename
#       end

#     end
#     sleep(1)
#     FileUtils.touch("test/helper.rb")
#     sleep(1)
#     Process.kill('SIGINT', @pid) rescue nil

#   end

end
