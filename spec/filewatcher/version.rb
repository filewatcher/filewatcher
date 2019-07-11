# frozen_string_literal: true

require_relative '../../lib/filewatcher/version'

describe Filewatcher::VERSION do
  it 'should exist as constant' do
    Filewatcher.const_defined?(:VERSION).should.be.true
  end

  it 'should be an instance of String' do
    Filewatcher::VERSION.class.should.equal String
  end
end
