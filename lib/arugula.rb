# frozen_string_literal: true
class Arugula
  require 'arugula/version'

  autoload :Parser, 'arugula/parser'

  def initialize(pattern)
    @root = Parser.new(pattern).parse!
  end

  def match?(str)
    index = 0
    loop do
      match, = @root.match(str, index)
      return index if match
      index += 1
      return if index > str.size
    end
  end

  def to_s
    "/#{@root}/"
  end
end
