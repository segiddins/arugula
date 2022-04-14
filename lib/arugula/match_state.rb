class Arugula
  class MatchState
    attr_reader :match_data
    def initialize(match_data:, str:, regexp:, idx:)
      @match_data = match_data
      @str = str
      @regexp = regexp
      @idx = idx
    end

    def match? = !@match_data.nil?

    def advanced(in_capture: nil, length: 1, reset_capture: false)
      captures = match_data&.instance_variable_get(:@captures) || {}
      start_index = match_data&.instance_variable_get(:@start_index) || @idx
      new_match_data =
        MatchData.new(match_data&.regexp || @regexp, @str, captures, start_index, @idx + length)
      if in_capture
        captures = captures.dup
        range = (!reset_capture && captures[in_capture]) || (@idx..@idx)
        range = range.begin...(@idx + length)
        captures[in_capture] = range
        new_match_data = MatchData.new(
          new_match_data.regexp, new_match_data.string, captures, start_index, @idx + length)
      end
      self.class.new(
        match_data: new_match_data,
        str: @str,
        regexp: @regexp,
        idx: @idx + length,
      ).freeze
    end
    
    def no_match(length: 0)
      self.class.new(
        match_data: nil,
        str: @str,
        regexp: @regexp,
        idx: @idx - length,
      ).freeze
    end

    def no_match_advanced = no_match(length: -1)
    
    def peek(length: 1)
      @str[@idx, length] unless eos?
    end

    def substring(start, length = 1)
      @str[@idx + start, length]
    end

    def past_eos? = @idx > @str.size
    def eos? = @idx == @str.size
    def sos? = @idx.zero?
  end
end
