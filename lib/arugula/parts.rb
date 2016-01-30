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
      literal.gsub('\\', '\\\\')
    end

    def match(str, index)
      length = literal.size
      matches = str[index, length] == literal
      [matches, index + (matches ? length : 0)]
    end
  end

  class AndPart < Part
    attr_accessor :parts
    def initialize
      @parts = []
    end

    def to_s
      parts.join
    end

    def match(str, index)
      parts.each do |part|
        match, index = part.match(str, index)
        return false, index unless match
      end
      [true, index]
    end
  end

  module MatchAny
    attr_accessor :parts
    def initialize
      @parts = []
    end

    def match(str, index)
      parts.each do |part|
        match, match_index = part.match(str, index)
        return true, match_index if match
      end
      [false, index]
    end
  end

  class OrPart < Part
    include MatchAny
    def to_s
      parts.join '|'
    end
  end

  class CharacterClassPart < Part
    include MatchAny
    def to_s
      "[#{parts.join}]"
    end
  end

  class RangePart < Part
    def initialize(start, final)
      @range = start..final
    end

    def to_s
      "#{@range.begin}-#{@range.end}"
    end

    def match(str, index)
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

    def match(str, index)
      [MATCHERS[@metachar][str, index], index + OFFSETS[@metachar]]
    end

    def to_s
      "\\#{@metachar}"
    end
  end

  class MatchPart < Part
    attr_accessor :parts
    def initialize
      @parts = AndPart.new
    end

    def to_s
      "(#{parts.join})"
    end
  end

  class EOLPart < Part
    def to_s
      '$'
    end

    def match(str, index)
      matches = str[index] == "\n" || index == str.size
      return true, index + 1 if matches
      [false, index]
    end
  end
  class SOLPart < Part
    def to_s
      '^'
    end

    def match(str, index)
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

  class StarPart < Part
    include Wrapping
    def to_s
      "#{wrapped}*"
    end

    def match(str, index)
      loop do
        matches, index = wrapped.match(str, index)
        return true, index unless matches
      end
    end
  end

  class PlusPart < Part
    include Wrapping
    def to_s
      "#{wrapped}+"
    end

    def match(str, index)
      has_matched = false
      loop do
        matches, index = wrapped.match(str, index)
        has_matched = true if matches
        return has_matched, index unless matches
      end
    end
  end

  class DotPart < Part
    def to_s
      '.'
    end

    def match(str, index)
      matches = index < str.size
      [matches, index + (matches ? 1 : 0)]
    end
  end
end
