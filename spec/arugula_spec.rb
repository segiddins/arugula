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
    'Hello ([a-z]+)!' => 'Hello world!',
    'a(b(b*))c' => '1ab2abbbc',
    '(\d+),(\d+),(\d+)' => '1,20,3',
    'foo|bar|baz' => 'foo',
    '(foo|bar|baz)' => 'fubar-ed',
    'this is (\d+|not)' => 'this is 10pm',
    '.' => '',
    '' => 'I like pizza.',
    '[()\\[\\].-]\\.' => 'hi',
    'foo[a-z]?' => 'food?',
    'a(b)?c' => 'factual',
    'a(b)?c(d)?' => 'ab acd',
    'a{2}b{,4}c{3,}d{6,8}' => 'a' * 2 + 'b' * 3 + 'c' * 4 + 'd' * 7,
    'fo{1,3}?d' => 'I like eating food',
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
        it 'does the same thing as ::Regexp' do
          expect(subject.match?(string)).to eq(regexp =~ string)
        end

        it 'returns the correct match data' do
          match = subject.match(string)
          expected = regexp.match(string)
          expect(match.to_a).to eq(expected.to_a)
          expect(match.to_s).to eq(expected.to_s)
          expect(match.inspect).to eq(expected.inspect)
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
