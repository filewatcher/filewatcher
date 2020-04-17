# frozen_string_literal: true

require_relative '../../lib/filewatcher/env'

describe Filewatcher::Env do
  subject(:initialization) { described_class.new(file, event) }

  let(:file) { __FILE__ }
  let(:event) { :updated }

  describe '#initialize' do
    it { expect { initialization }.not_to raise_error ArgumentError }
  end

  describe '#to_h' do
    subject { super().to_h }

    it { is_expected.to be_kind_of Hash }

    describe '#[]' do
      subject { super()[key] }

      describe 'key "FILEPATH"' do
        let(:key) { 'FILEPATH' }

        context 'when event is `:created`' do
          let(:event) { :created }

          it { is_expected.to eq __FILE__ }
        end

        context 'when event is `:updated`' do
          let(:event) { :updated }

          it { is_expected.to eq __FILE__ }
        end

        context 'when event is `:deleted`' do
          let(:event) { :deleted }

          it { is_expected.to be_nil }
        end
      end

      context 'when file is `__FILE__`' do
        let(:file) { __FILE__ }

        describe 'key "FILENAME"' do
          let(:key) { 'FILENAME' }

          it { is_expected.to eq __FILE__ }
        end

        describe 'key "BASENAME"' do
          let(:key) { 'BASENAME' }

          it { is_expected.to eq File.basename(__FILE__) }
        end

        describe 'key "DIRNAME"' do
          let(:key) { 'DIRNAME' }

          it { is_expected.to eq File.dirname(__FILE__) }
        end

        describe 'key "ABSOLUTE_FILENAME"' do
          let(:key) { 'ABSOLUTE_FILENAME' }

          it { is_expected.to eq __FILE__ }
        end

        describe 'key "RELATIVE_FILENAME"' do
          let(:key) { 'RELATIVE_FILENAME' }

          it { is_expected.to eq __FILE__.sub("#{Dir.pwd}/", '') }
        end
      end

      describe 'key "EVENT"' do
        let(:key) { 'EVENT' }

        context 'when event is `:updated`' do
          let(:event) { :updated }

          it { is_expected.to eq 'updated' }
        end
      end
    end
  end
end
