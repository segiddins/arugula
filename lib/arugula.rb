# frozen_string_literal: true
class Arugula
  require 'arugula/version'

  attr_reader :captures

  autoload :MatchData, 'arugula/match_data'
  autoload :Parser, 'arugula/parser'

  def initialize(pattern)
    @root, @captures = Parser.new(pattern).parse!
  end

  def match?(str, index = 0)
    match_data = match(str, index)
    match_data && match_data.start_index
  end

  def match(str, index = 0)
    match_data = MatchData.new(self, str)
    loop do
      match_data.reset_captures!
      match, end_index = @root.match(str, index, match_data)
      if match
        match_data.start_index = index
        match_data.end_index = end_index
        return match_data.freeze
      end
      index += 1
      return if index > str.size
    end
  end

  def to_s
    "/#{@root}/"
  end
end
