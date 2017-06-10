# frozen_string_literal: true

require_relative '../../lib/filewatcher/runner'

describe Filewatcher::Runner do
  before do
    @init = proc do |filename|
      Filewatcher::Runner.new(filename)
    end
  end

  describe '#initialize' do
    it 'should recieve filename' do
      -> { @init.call('file.txt') }
        .should.not.raise ArgumentError
    end
  end

  describe '#command' do
    it 'should return correct command for file with .py extension' do
      @init.call('file.py').command
        .should.equal 'env python file.py'
    end

    it 'should return correct command for file with .js extension' do
      @init.call('file.js').command
        .should.equal 'env node file.js'
    end

    it 'should return correct command for file with .rb extension' do
      @init.call('file.rb').command
        .should.equal 'env ruby file.rb'
    end

    it 'should return correct command for file with .pl extension' do
      @init.call('file.pl').command
        .should.equal 'env perl file.pl'
    end

    it 'should return correct command for file with .awk extension' do
      @init.call('file.awk').command
        .should.equal 'env awk file.awk'
    end

    it 'should return correct command for file with .php extension' do
      @init.call('file.php').command
        .should.equal 'env php file.php'
    end

    it 'should return correct command for file with .phtml extension' do
      @init.call('file.phtml').command
        .should.equal 'env php file.phtml'
    end

    it 'should return correct command for file with .php4 extension' do
      @init.call('file.php4').command
        .should.equal 'env php file.php4'
    end

    it 'should return correct command for file with .php3 extension' do
      @init.call('file.php3').command
        .should.equal 'env php file.php3'
    end

    it 'should return correct command for file with .php5 extension' do
      @init.call('file.php5').command
        .should.equal 'env php file.php5'
    end

    it 'should return correct command for file with .phps extension' do
      @init.call('file.phps').command
        .should.equal 'env php file.phps'
    end
  end
end
