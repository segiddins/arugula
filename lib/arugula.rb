# frozen_string_literal: true
class Arugula
  require 'arugula/version'

  attr_reader :captures

  autoload :Compiler, 'arugula/compiler'
  autoload :MatchData, 'arugula/match_data'
  autoload :MatchState, 'arugula/match_state'
  autoload :Parser, 'arugula/parser'

  def initialize(pattern)
    @root, @captures = Parser.new(pattern).parse!
  end

  def match?(str, index = 0)
    match_data = match(str, index)
    match_data&.instance_variable_get(:@start_index)
  end

  def compile
    @compile ||= Compiler.compile!(@root)
  end

  def match(str, index = 0)
    compile.run(self, str, index)
  end

  def to_s
    "/#{@root}/"
  end

  alias inspect to_s

  def hash
    to_s.hash
  end

  def ==(other)
    return false unless other.is_a?(Arugula) || other.is_a?(Regexp)
    inspect == other.inspect
  end
end
