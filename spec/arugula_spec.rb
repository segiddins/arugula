require 'spec_helper'

describe Arugula do
  it 'has a version number' do
    expect(Arugula::VERSION).not_to be_nil
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
      subject { Arugula.new(pattern) }
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
end
