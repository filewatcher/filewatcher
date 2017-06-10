# frozen_string_literal: true

require_relative '../../lib/filewatcher/env'

describe Filewatcher::Env do
  describe '#initialize' do
    it 'should recieve filename and event' do
      -> { Filewatcher::Env.new(__FILE__, :updated) }
        .should.not.raise ArgumentError
    end
  end

  describe '#to_h' do
    before do
      @init = proc do |file: __FILE__, event: :updated|
        Filewatcher::Env.new(file, event).to_h
      end
      @env = @init.call
    end

    it 'should return Hash' do
      @env.should.be.kind_of Hash
    end

    it 'should return Hash with FILEPATH key for created event' do
      @init.call(event: :created)['FILEPATH']
        .should.equal File.join(Dir.pwd, __FILE__)
    end

    it 'should return Hash with FILEPATH key for updated event' do
      @init.call(event: :updated)['FILEPATH']
        .should.equal File.join(Dir.pwd, __FILE__)
    end

    it 'should return Hash without FILEPATH key for deleted event' do
      @init.call(event: :deleted)['FILEPATH']
        .should.equal nil
    end

    it 'should return Hash with FILENAME key' do
      @init.call(file: __FILE__)['FILENAME']
        .should.equal __FILE__
    end

    it 'should return Hash with BASENAME key' do
      @init.call(file: __FILE__)['BASENAME']
        .should.equal File.basename(__FILE__)
    end

    it 'should return Hash with EVENT key' do
      @init.call(event: :updated)['EVENT']
        .should.equal 'updated'
    end

    it 'should return Hash with DIRNAME key' do
      @init.call(file: __FILE__)['DIRNAME']
        .should.equal File.dirname(File.join(Dir.pwd, __FILE__))
    end

    it 'should return Hash with ABSOLUTE_FILENAME key' do
      @init.call(file: __FILE__)['ABSOLUTE_FILENAME']
        .should.equal File.join(Dir.pwd, __FILE__)
    end

    it 'should return Hash with RELATIVE_FILENAME key' do
      @init.call(file: __FILE__)['RELATIVE_FILENAME']
        .should.equal __FILE__
    end
  end
end
