require 'rubygems'
require 'minitest/autorun'
require_relative '../lib/filewatcher'

describe FileWatcher do

  filewatcher = FileWatcher.new([])

  it "can find single files" do
    files = filewatcher.expand_directories(["fixtures/file1.txt"])
    assert files.size == 1
  end

  it "can expand directories recursively" do
    files = filewatcher.expand_directories(["fixtures/"])
    assert files.size == 6
    files = filewatcher.expand_directories(["fixtures"])
    assert files.size == 6
    files = filewatcher.expand_directories(["./fixtures"])
    assert files.size == 6
  end

  it "can use filename globbing to filter names" do
    files = filewatcher.expand_directories(["fixtures/*.rb"])
    assert files.size == 2
  end

end
