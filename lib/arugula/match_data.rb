class Arugula
  class MatchData
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
      @captures.map { |_name, range| range && @string[range] }.unshift(to_s)
    end

    def freeze
      @captures.freeze
      super
    end

    private

    def dump_str(str)
      str.nil? ? 'nil' : str.dump
    end
  end
end
