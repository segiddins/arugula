require 'arugula/parts'

class Arugula
  class Parser
    attr_reader :pattern
    def initialize(str)
      @pattern = str.dup
      @states = [AndPart.new]
      @captures = []
    end

    def state
      @states.reverse_each.find { |s| s.respond_to?(:parts) }
    end

    def parse!
      consume until pattern.empty?
      [@states.first, @captures]
    end

    Part.all.each do |part|
      type = part.type
      define_method(:"#{type}_type?") do
        return true if state && state.class.type == type
      end
    end

    def consume
      tok = pattern.slice!(0)
      peek = pattern.chr
      if tok.nil?
        fail 'shouldnt happen'
      elsif tok == '[' && !characterclass_type?
        push_part(:characterclass)
      elsif tok == '-' &&
            characterclass_type? &&
            state.parts.last.class.type == :literal &&
            peek != ']'
        literal = state.parts.pop
        push_part(:range, literal.literal, peek)
        pattern.slice!(0)
      elsif tok == ']' && characterclass_type?
        pop_part
      elsif tok == '^' && characterclass_type? && state.parts.empty?
        characterclass_part = pop_part
        wrap_state(:not)
        @states << characterclass_part
      elsif tok == '$'
        push_part(:eol)
      elsif tok == '^'
        push_part(:sol)
      elsif tok == "\\"
        case peek
        when nil
          fail 'unterminated escape sequence'
        when *MetacharacterPart::MATCHERS.keys.map(&:to_s)
          push_part(:metacharacter, peek)
        when *LiteralPart::SPECIAL_LITERALS_BY_REGEX.keys
          push_part(:literal, LiteralPart::SPECIAL_LITERALS_BY_REGEX[peek])
        else
          push_part(:literal, peek)
        end
        pattern.slice!(0)
      elsif characterclass_type?
        push_part(:literal, tok)
      elsif tok == '('
        push_capture
      elsif tok == ')'
        pop_part until capture_type?
        pop_part
      elsif tok == '|'
        pop_part until state == @states.first || or_type? || capture_type?
        wrap_state(:or) unless or_type?
        push_part(:and)
      elsif tok == '.'
        push_part(:dot)
      elsif tok == '*'
        wrap_state(:star)
      elsif tok == '+'
        wrap_state(:plus)
      elsif tok == '?'
        wrap_state(:question)
      elsif tok == '{'
        before_comma = ''
        after_comma = ''
        until pattern.chr == ',' || pattern.chr == '}'
          before_comma << pattern.slice!(0)
        end
        if pattern.chr == ','
          pattern.slice!(0)
        else
          after_comma = before_comma
        end
        after_comma << pattern.slice!(0) until pattern.chr == '}'
        pattern.slice!(0) if pattern.chr == '}'
        before = before_comma.empty? ? 0 : before_comma.to_i
        after = after_comma.empty? ? Float::INFINITY : after_comma.to_i
        wrap_state(:quantifier, before, after)
      else
        push_part(:literal, tok)
      end
    end

    def push_part(name, *content)
      part_class = Part.all.find { |p| p.type == name }
      fail "Unknown part type #{name}" unless part_class
      part = part_class.new(*content)
      state.parts << part
      @states << part unless name == :literal
    end

    def wrap_state(name, *content)
      wrapped = Part.all.find { |p| p.type == name }
                    .new(*content, state.parts.pop)
      state.parts << wrapped
      @states << wrapped
    end

    def pop_part
      @states.pop until @states.last.respond_to?(:parts)
      @states.pop
    end

    def push_capture
      push_part(:capture, @captures.size.succ)
      @captures << state
      push_part(:and)
    end
  end
end
