# frozen_string_literal: true

require_relative '../../lib/filewatcher/version'

describe 'Filewatcher::VERSION' do
  subject { Object.const_get(self.class.description) }

  it { is_expected.to be_kind_of String }

  it { is_expected.not_to be_empty }
end
