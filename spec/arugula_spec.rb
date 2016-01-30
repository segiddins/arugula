require 'spec_helper'

describe Arugula do
  it 'has a version number' do
    expect(Arugula::VERSION).to match(Gem::Version::ANCHORED_VERSION_PATTERN)
  end

  {
    'a' => 'a',
    'foo' => 'e-food',
    '[eat]' => 'hfkdshgfjds',
    '\\A\\de' => '5eat',
    '^line$' => "before\nline\nafter",
    'a*bc*' => 'caaaaaaaab',
    'a+bc+' => 'caaaaaaaabcc',
    '[a-z]' => 'AfG',
    '[A-Z].+' => 'my name is Samuel Giddins',
    '[e-gE-G]' => 'cow is GREAT',
  }.each do |pattern, string|
    ruby_pattern = "/#{pattern}/"

    context "#{string.dump} =~ #{ruby_pattern}" do
      subject { described_class.new(pattern) }
      let(:regexp) { Regexp.new(pattern) }

      describe '#to_s' do
        it 'returns the original pattern' do
          expect(subject.to_s).to eq(ruby_pattern)
        end
      end

      context 'when matching a string' do
        it 'does the same this as ::Regexp' do
          expect(subject.match?(string)).to eq(regexp =~ string)
        end
      end
    end
  end

  context 'when matching from a starting offset' do
    let(:pattern) { 'ab' }
    subject { described_class.new(pattern) }

    it "doesn't match when the match is before the passed in position" do
      expect(subject.match?('abcd', 2)).to be_nil
    end

    it 'returns the match index' do
      expect(subject.match?('ababababab', 3)).to eq(4)
    end
  end
end
