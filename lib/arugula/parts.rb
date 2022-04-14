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

    SPECIAL_LITERALS_BY_STRING = { 
      "\n" => '\n', 
      "\t" => '\t', 
      '.' => '\.', 
      '/' => '\/',
      "\\" => "\\\\", 
    }.freeze
    SPECIAL_LITERALS_BY_STRING_UNION = Regexp.union(SPECIAL_LITERALS_BY_STRING.keys)
    SPECIAL_LITERALS_BY_REGEX = SPECIAL_LITERALS_BY_STRING.invert.transform_keys { _1[1, 1] }.freeze

    def to_s
      literal.
        gsub(SPECIAL_LITERALS_BY_STRING_UNION, SPECIAL_LITERALS_BY_STRING)
    end

    def to_matcher_parts!(compiler)
      compiler.automata!(self) do |state|
        length = literal.size
        if state.peek(length: length) == literal
          state.advanced(length: length)
        else
          state.no_match
        end
      end
    end
  end

  module MatchAll
    attr_accessor :parts
    def initialize
      @parts = []
    end

    def to_matcher_parts!(compiler)
      compiler.conjunction(parts)
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

    def to_matcher_parts!(compiler) = compiler.disjunction(parts)
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

    def to_matcher_parts!(compiler)
      compiler.automata!(self) do |state|
        if @range.member?(state.peek)
          state.advanced
        else
          state.no_match
        end
      end
    end
  end

  class MetacharacterPart < Part
    MATCHERS = {
      A: ->(_str, index) { index == 0 },
      d: ->(str, index) { ('0'..'9').member?(str[index]) },
      s: ->(str, index) { [' ', "\t"].include?(str[index]) },
      S: ->(str, index) { ![' ', "\t"].include?(str[index]) },
      z: ->(str, index) { index == str.size },
      Z: ->(str, index) { str[index..-1] == "\n" || index == str.size },
    }.freeze

    OFFSETS = begin
      offsets = {
        A: ->(_str, _index) { 0 },
        Z: ->(_str, _index) { 0 },
        z: ->(_str, _index) { 0 },
      }
      offsets.default = ->(_str, _index) { 1 }
      offsets.freeze
    end

    def initialize(metachar)
      @metachar = metachar.to_sym
    end

    def to_s
      "\\#{@metachar}"
    end

    def to_matcher_parts!(compiler)
      compiler.automata!(self) do |state|
        case @metachar
        when :A
          state.advanced(length: 0) if state.sos?
        when :d
          state.advanced if ('0'..'9').member?(state.peek)
        when :s
          raise
        when :S
          raise
        when :z
          state.advanced(length: 0) if state.eos?
        when :Z
          eos = state
          eos = eos.advanced if eos.peek == "\n"
          state.advanced(length: 0) if eos.eos?
        end.yield_self { _1 || state.no_match }
      end
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

    def to_matcher_parts!(compiler)
      @parts.each do |part|
        compiler.add_successor_from_current_to_next do
          compiler.automata!("Start capture #{name}") { |state| state.advanced(in_capture: name, length: 0, reset_capture: true) }
        end
      
        compiler.add_successor_from_current_to_next do
          part.to_matcher_parts!(compiler)
        end

        compiler.add_successor_from_current_to_next do
          compiler.automata!("End capture #{name}") { |state| state.match? ? state.advanced(in_capture: name, length: 0) : state }
        end
      end
    end
  end

  class EOLPart < Part
    def to_s
      '$'
    end

    def to_matcher_parts!(compiler)
      compiler.automata!(self) do |state|
        next state.advanced(length: 0) if state.eos? || state.peek == "\n"
        state.no_match
      end
    end
  end
  class SOLPart < Part
    def to_s
      '^'
    end

    def to_matcher_parts!(compiler)
      compiler.automata!(self) do |state|
        next state.advanced(length: 0) if state.sos? || state.substring(-1) == "\n"
        state.no_match
      end
    end
  end

  module Wrapping
    attr_reader :wrapped
    def initialize(wrapped)
      @wrapped = wrapped
    end
  end

  class NotPart < Part
    include Wrapping

    def to_s
      @wrapped.to_s.dup.insert(1, '^')
    end

    def to_matcher_parts!(compiler)
      compiler.with_negation { wrapped.to_matcher_parts!(compiler) }
    end
  end

  module MatchNTimes
    include Wrapping
    def initialize(*args, times: 1..1)
      @times = times
      super(*args)
    end

    def to_matcher_parts!(compiler)
      compiler.repeated_range(wrapped, @times.begin, @times.end)
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

    def to_matcher_parts!(compiler)
      compiler.automata!(self) { _1.peek&.!=("\n") ? _1.advanced : _1.no_match }
    end
  end
end
