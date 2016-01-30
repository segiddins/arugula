class Arugula
  class MatchData
    def initialize(regexp, string)
      # require "awesome_print"
      # ap regexp, raw: true
      @regexp = regexp
      @string = string.dup.freeze
      @captures = Hash[regexp.captures.map {|c| [c.name, nil] }]
    end

    def add_capture(name, start_index, end_index)
      @captures[name] = start_index...end_index
    end

    attr_accessor :start_index
    attr_accessor :end_index

    def to_s
      @string[start_index...end_index]
    end

    def inspect
      captures_part = @captures.
        map {|name, range| " #{name}:#{@string[range].dump}"}.join
      "#<MatchData #{to_s.dump}#{captures_part}>"
    end

    def to_a
      @captures.map {|name, range| @string[range] }.unshift(to_s)
    end

    def freeze
      super
      @captures.freeze
    end
  end
end
