# frozen_string_literal: true

require_relative '../../lib/filewatcher/version'

describe 'Filewatcher::VERSION' do
  subject { Object.const_get(self.class.description) }

  it { is_expected.to match(/^\d+\.\d+\.\d+(\.\w+(\.\d+)?)?$/) }
end
