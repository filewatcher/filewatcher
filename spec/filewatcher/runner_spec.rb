# frozen_string_literal: true

require_relative '../../lib/filewatcher/runner'

describe Filewatcher::Runner do
  subject { described_class.new(filename) }

  let(:filename) { nil }

  describe '#command' do
    subject { super().command }

    context 'with `*.py` file' do
      let(:filename) { 'file.py' }

      it { is_expected.to eq 'env python file.py' }
    end

    context 'with `*.js` file' do
      let(:filename) { 'file.js' }

      it { is_expected.to eq 'env node file.js' }
    end

    context 'with `*.rb` file' do
      let(:filename) { 'file.rb' }

      it { is_expected.to eq 'env ruby file.rb' }
    end

    context 'with `*.pl` file' do
      let(:filename) { 'file.pl' }

      it { is_expected.to eq 'env perl file.pl' }
    end

    context 'with `*.awk` file' do
      let(:filename) { 'file.awk' }

      it { is_expected.to eq 'env awk file.awk' }
    end

    context 'with `*.php` file' do
      let(:filename) { 'file.php' }

      it { is_expected.to eq 'env php file.php' }
    end

    context 'with `*.phtml` file' do
      let(:filename) { 'file.phtml' }

      it { is_expected.to eq 'env php file.phtml' }
    end

    context 'with `*.php4` file' do
      let(:filename) { 'file.php4' }

      it { is_expected.to eq 'env php file.php4' }
    end

    context 'with `*.php3` file' do
      let(:filename) { 'file.php3' }

      it { is_expected.to eq 'env php file.php3' }
    end

    context 'with `*.php5` file' do
      let(:filename) { 'file.php5' }

      it { is_expected.to eq 'env php file.php5' }
    end

    context 'with `*.phps` file' do
      let(:filename) { 'file.phps' }

      it { is_expected.to eq 'env php file.phps' }
    end
  end
end
