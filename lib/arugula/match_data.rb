class Arugula
  class MatchData
    attr_reader :string, :regexp
    def initialize(regexp, string, captures, start_index, end_index)
      @regexp = regexp
      @string = string.dup.freeze
      @captures = regexp.captures.to_h { [_1.name, nil] }.merge(captures).freeze
      @start_index = start_index
      @end_index = end_index
    end

    def to_s
      @string[@start_index...@end_index]
    end

    def inspect
      captures_part = @captures.map do |name, range|
        " #{name}:#{dump_str(range && @string[range])}"
      end.join
      "#<MatchData #{dump_str(to_s)}#{captures_part}>"
    end

    def to_a
      captures.unshift(to_s)
    end

    def size
      @captures.size + 1
    end
    alias length size

    def captures
      @captures.map { |_name, range| range && @string[range] }
    end

    def pre_match
      return '' if @start_index == 0
      @string[0...@start_index]
    end

    def post_match
      return '' if @end_index == string.size
      @string[@end_index..-1]
    end

    def names = []
    def named_captures = {}

    def [](idx)
      idx.zero? ? to_s : captures[idx - 1]
    end
    alias match []
  
    def begin(idx)
      idx.zero? ? @start_index : @captures[idx]&.begin
    end
  
    def end(idx)
      idx.zero? ? @end_index : @captures[idx]&.end
    end

    def match_length(idx)
      idx.zero? ? @end_index - @start_index : @captures[idx]&.size
    end

    def offset(idx)
      [self.begin(idx), self.end(idx)]
    end

    def values_at(*idx)
      idx.map { match(_1) }
    end

    def hash
      @string.hash ^ @regexp.hash ^ @captures.hash
    end

    def ==(other)
      return false unless other.is_a?(MatchData) || other.is_a?(::MatchData)
      string == other.string &&
        regexp == other.regexp &&
        captures == other.captures
    end

    private

    def dump_str(str)
      str.nil? ? 'nil' : str.dump
    end
  end
end
