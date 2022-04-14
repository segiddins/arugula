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
    '^line$' => ["before\nline\nafter", "\nline", "line\n", "\nline\n", "\nline\naline"],
    'l1\nl2' => ["l1\nl2", "l1l2"],
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
    'fo[a-z]?' => 'fo?',
    'a(b)?c' => 'factual',
    'a(b)?c(d)?' => 'ab acd',
    'a{2}b{,4}c{3,}d{6,8}' => 'a' * 2 + 'b' * 3 + 'c' * 4 + 'd' * 7,
    'fo{1,3}?d' => 'I like eating food',
    '.([0-9]){3,5}?foo' => '9876543210foo',
    '(foo\z)' => 'bar foo',
    '(foo\Z)' => "bar foo\n\n",
    '(food\Z)' => "bar food\n",
    '(foody\Z)' => 'bar foody',
    '[^abc]' => 'abcd',
    '<.*>' => ['<a>foo</a>', '<<a>>', '<><><', '<>'],
    '<.+>' => ['<a>foo</a>', '<<a>>', '<><><', '<>'],
    'a(.*)>' => '<a>foo</a>',
    '<.{1,}>' => '<a>foo</a>',
    'foo(A{,1}+)Abar' => 'fooAAAbar',
    'foo(A{,1}+)Aba' => 'fooAbar',
    'foo(A{,1}+)Ab' => 'fooAAbar',
    '^.{2}*$' => '1212',
    '^.{3}*$' => '12312',
    '\/' => '/',
  }.each do |pattern, strings|
    ruby_pattern = "/#{pattern}/"
    match_data_methods = %i(
      itself
      to_a to_s inspect post_match pre_match
      captures length size string regexp
      named_captures names
    )
    match_data_index_methods = %i(
      []
      begin end match match_length offset values_at
    )
    regexp = Regexp.new(pattern)
    Array(strings).each do |string|
      expected_match = regexp.match(string)

      context "#{string.dump} =~ #{ruby_pattern}" do
        subject { described_class.new(pattern) }
        let(:match) { subject.match(string) }

        describe '#to_s' do
          it 'returns the original pattern' do
            expect(subject.to_s).to eq(ruby_pattern)
          end
        end

        context 'when matching a string' do
          it 'does the same thing as ::Regexp' do
            expect(subject.match?(string)).to eq(regexp =~ string)
          end

          it 'returns the same MatchData as ::Regexp' do
            expect(match).to eq(expected_match)
          end

          unless expected_match.nil?
            match_data_methods.each do |m|
              it "returns the correct value for #{m}" do
                expect(match.send(m)).to eq(expected_match.send(m))
              end
            end

            match_data_index_methods.each do |m|
              describe "calling ##{m}" do
                expected_match.size.times do |idx|
                  it "returns the correct value for .(#{idx.inspect})" do
                    expect(match.send(m, idx)).to eq(expected_match.send(m, idx))
                  end
                end
              end
            end
          end
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

  it 'supports . (any character except line terminator)' do
    # Basic matching
    expect(Arugula.new('.').match('foo').to_a).to eq ['f']
    # Basic non-matching
    expect(Arugula.new('.').match('')).to be_nil
    expect(Arugula.new('.').match("\n")).to be_nil
    expect(Arugula.new('.').match("\0").to_a).to eq ["\0"]
  end

  it 'support quoting meta-characters via escape sequence' do
    expect(Arugula.new('\\\\').match('\\').to_a).to eq ['\\']
    expect(Arugula.new('\/').match('/').to_a).to eq ['/']
    # parenthesis, etc
    expect(Arugula.new('\(').match('(').to_a).to eq ['(']
    expect(Arugula.new('\)').match(')').to_a).to eq [')']
    expect(Arugula.new('\[').match('[').to_a).to eq ['[']
    expect(Arugula.new('\]').match(']').to_a).to eq [']']
    expect(Arugula.new('\{').match('{').to_a).to eq ['{']
    expect(Arugula.new('\}').match('}').to_a).to eq ['}']
    # alternation separator
    expect(Arugula.new('\|').match('|').to_a).to eq ['|']
    # quantifiers
    expect(Arugula.new('\?').match('?').to_a).to eq ['?']
    expect(Arugula.new('\.').match('.').to_a).to eq ['.']
    expect(Arugula.new('\*').match('*').to_a).to eq ['*']
    expect(Arugula.new('\+').match('+').to_a).to eq ['+']
    # line anchors
    expect(Arugula.new('\^').match('^').to_a).to eq ['^']
    expect(Arugula.new('\$').match('$').to_a).to eq ['$']
  end
end
