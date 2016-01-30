class Arugula
  class MatchData
    attr_reader :string, :regexp
    def initialize(regexp, string)
      # require "awesome_print"
      # ap regexp, raw: true
      @regexp = regexp
      @string = string.dup.freeze
      @captures = Hash[regexp.captures.map { |c| [c.name, nil] }]
    end

    def add_capture(name, start_index, end_index)
      @captures[name] = start_index...end_index
    end

    def reset_captures!
      @captures.keys.each do |key|
        @captures[key] = nil
      end
    end

    attr_accessor :start_index
    attr_accessor :end_index

    def to_s
      @string[start_index...end_index]
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
      return '' if start_index == 0
      @string[0...start_index]
    end

    def post_match
      return '' if end_index == string.size
      @string[end_index..-1]
    end

    def freeze
      @captures.freeze
      super
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
