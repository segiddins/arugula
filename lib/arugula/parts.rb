# frozen_string_literal: true
class Arugula
  class Part
    def self.all
      @all ||= []
    end

    def self.inherited(subclass)
      all << subclass
    end

    def self.type
      @type ||= name.split('::').last.downcase.chomp('part').to_sym
    end
  end

  class LiteralPart < Part
    attr_accessor :literal
    def initialize(literal)
      @literal = literal
    end

    def to_s
      literal.gsub('\\', '\\\\').gsub(/[.]/) { |m| "\\#{m}" }
    end

    def match(str, index, _match_data)
      length = literal.size
      matches = str[index, length] == literal
      [matches, index + (matches ? length : 0)]
    end
  end

  module MatchAll
    attr_accessor :parts
    def initialize
      @parts = []
    end

    def match(str, index, match_data)
      parts.each do |part|
        match, index = part.match(str, index, match_data)
        return false, index unless match
      end
      [true, index]
    end
  end

  class AndPart < Part
    include MatchAll
    def to_s
      parts.join
    end
  end

  module MatchAny
    attr_accessor :parts
    def initialize
      @parts = []
    end

    def match(str, index, match_data)
      parts.each do |part|
        match, match_index = part.match(str, index, match_data)
        return true, match_index if match
      end
      [false, index]
    end
  end

  class OrPart < Part
    include MatchAny
    def initialize(*parts)
      super()
      @parts += parts
    end

    def to_s
      parts.join '|'
    end
  end

  class CharacterClassPart < Part
    include MatchAny
    def to_s
      parts_string = parts.map do |part|
        next part unless part.class.type == :literal
        lit = part.literal
        lit = '\\]' if lit == ']'
        lit = '\\[' if lit == '['
        lit
      end.join
      "[#{parts_string}]"
    end
  end

  class RangePart < Part
    def initialize(start, final)
      @range = start..final
    end

    def to_s
      "#{@range.begin}-#{@range.end}"
    end

    def match(str, index, _match_data)
      matches = @range.member?(str[index])
      [matches, index + (matches ? 1 : 0)]
    end
  end

  class MetacharacterPart < Part
    MATCHERS = {
      A: ->(_str, index) { index == 0 },
      d: ->(str, index) { ('0'..'9').member?(str[index]) },
      s: ->(str, index) { [' ', "\t"].include?(str[index]) },
      S: ->(str, index) { ![' ', "\t"].include?(str[index]) },
    }.freeze

    OFFSETS = begin
      offsets = {
        A: 0,
      }
      offsets.default = 1
      offsets.freeze
    end

    def initialize(metachar)
      @metachar = metachar.to_sym
    end

    def match(str, index, _match_data)
      matches = MATCHERS[@metachar][str, index]
      [matches, index + (matches ? OFFSETS[@metachar] : 0)]
    end

    def to_s
      "\\#{@metachar}"
    end
  end

  class CapturePart < Part
    include MatchAll
    attr_reader :name

    def initialize(name)
      @name = name
      super()
    end

    def to_s
      "(#{parts.join})"
    end

    def match(str, index, match_data)
      matches, end_index = super
      match_data.add_capture(@name, index, end_index) if matches
      [matches, end_index]
    end
  end

  class EOLPart < Part
    def to_s
      '$'
    end

    def match(str, index, _match_data)
      matches = str[index] == "\n" || index == str.size
      return true, index if matches
      [false, index]
    end
  end
  class SOLPart < Part
    def to_s
      '^'
    end

    def match(str, index, _match_data)
      matches = (index == 0) || (str[index - 1] == "\n")
      [matches, index]
    end
  end

  module Wrapping
    attr_reader :wrapped
    def initialize(wrapped)
      @wrapped = wrapped
    end
  end

  module MatchNTimes
    include Wrapping
    def initialize(*args, times: 1..1)
      @times = times
      super(*args)
    end

    def match(str, index, match_data)
      match_count = 0
      end_index = index

      loop do
        matches, index = wrapped.match(str, index, match_data)
        if matches
          end_index = index
          match_count += 1
        end
        break if !matches || match_count > @times.end
      end

      matches = @times.member?(match_count)
      [matches, matches ? end_index : index]
    end
  end

  class StarPart < Part
    include MatchNTimes
    def initialize(*args)
      super(*args, times: 0..Float::INFINITY)
    end

    def to_s
      "#{wrapped}*"
    end
  end

  class PlusPart < Part
    include MatchNTimes
    def initialize(*args)
      super(*args, times: 1..Float::INFINITY)
    end

    def to_s
      "#{wrapped}+"
    end
  end

  class QuestionPart < Part
    include MatchNTimes
    def initialize(*args)
      super(*args, times: 0..1)
    end

    def to_s
      "#{wrapped}?"
    end
  end

  class QuantifierPart < Part
    include MatchNTimes
    def initialize(before, after, *args)
      super(*args, times: before..after)
    end

    def to_s
      before = @times.begin
      after = @times.end
      quantifier_part = '{'.dup
      quantifier_part << before.to_s unless before == 0
      quantifier_part << ',' unless before == after
      quantifier_part << after.to_s unless before == after ||
                                           after == Float::INFINITY
      quantifier_part << '}'
      "#{wrapped}#{quantifier_part}"
    end
  end

  class DotPart < Part
    def to_s
      '.'
    end

    def match(str, index, _match_data)
      matches = index < str.size
      [matches, index + (matches ? 1 : 0)]
    end
  end
end
