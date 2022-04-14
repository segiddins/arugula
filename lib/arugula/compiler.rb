class Arugula
  class Compiler
    class Automata
      attr_reader :name
      def initialize(name, &blk)
        @name = name
        @blk = blk
      end
  
      def call(state)
        # pp(state:, name: @name.to_s)
        @blk.call(state) or raise("#{name} called with #{state} failed to return a new state")
      end
    end

    def self.compile!(root_node)
      new(root_node)
    end

    def initialize(root_node)
      @parts = []
      automata!('start') { _1.advanced(length: 0) }
      @successors = Hash.new { |h, k| h[k] = [] }
      root_node.to_matcher_parts!(self)
      
      add_successor(
        to: automata!('terminal') { |state| state.advanced(length: 0) }
      )
      @successors[@parts.last]
  
      automata!('no_match_advanced') do |state|
        state.match? ? state : state.no_match_advanced
      end
  
      @successors.each_value(&:uniq!)

      @negated = false

      freeze
    end
    private_class_method :new

    def automata!(name, &blk)
      if @negated
        input_blk = blk
        blk = proc do |state|
          new_state = input_blk.call(state)
          if new_state.match?
            state.no_match
          else
            new_state.advanced(length: 1)
          end
        end
      end

      Automata.new(@negated ? "^ #{name}" : name, &blk).tap { @parts << _1 }
    end

    def phi!
      automata!("phi_#{@parts.size}") { _1 }
    end

    def add_successor(from: @parts[-2], to: nil)
      raise ArgumentError, "Missing to:" unless to
      @successors[from] << to
    end
    
    def conjunction(parts) = @negated ? _disjunction(parts) : _conjunction(parts)
    def disjunction(parts) = @negated ? _conjunction(parts) : _disjunction(parts)

    def _conjunction(parts)
      parts.each do |part|
        add_successor_from_current_to_next do
          part.to_matcher_parts!(self)
        end
      end
    end

    def _disjunction(parts)
      prev = current_part
      phi_in = []
      parts.each do |part|
        n = next_part

        part.to_matcher_parts!(self)

        add_successor(
          from: prev,
          to: n.call
        )

        phi_in << current_part
      end
      phi = phi!
      phi_in.each { add_successor(from: _1, to: phi) }
    end

    def repeated_range(part, min, max)
      raise if @negated

      min.times do
        add_successor_from_current_to_next do 
          part.to_matcher_parts!(self)
        end
      end

      terminals = [current_part]

      if max.infinite?
        n = next_part
        add_successor_from_current_to_next do
          part.to_matcher_parts!(self)
        end
        add_successor(from: current_part, to: n.call)
        terminals << current_part
      else
        int = []
        (max - min).times do
          add_successor_from_current_to_next do
            part.to_matcher_parts!(self)
          end
          terminals << current_part
        end
        int.each { _1.call }
      end

      phi!.tap do |phi|
        terminals.each { add_successor(from: _1, to: phi) }
      end
    end

    def with_negation(&blk)
      negated = @negated
      @negated = !@negated
      yield
    ensure
      @negated = negated
    end

    def add_successor_from_current_to_next(&blk)
      curr = current_part
      nex = next_part
      yield
      part = nex.call
      raise "No parts added: top of stack is still #{curr.pretty_inspect}" if part.equal?(curr)
      add_successor(from: curr, to: part)
    end

    def current_part
      @parts.last
    end

    def next_part
      idx = @parts.size
      -> { @parts.fetch(idx) }
    end

    def freeze
      @parts.freeze
      @successors.freeze.each_value(&:freeze)
      super
    end

    def run(regexp, str, index)
      start = @parts.first
      stack = [
        [start, MatchState.new(
          match_data: nil,
          str: str,
          regexp: regexp,
          idx: index
        )],
      ]
  
      # @successors.each do |part, succs|
      #   succs.each do |s|
      #     puts "  #{part.name} -> #{s.name}"
      #   end
      # end
  
      no_match_advanced = @parts.last
  
      end_state = loop do
        automata, state = stack.pop
  
        new_state = automata.call(state)
        
        if new_state.match?
          succ = @successors.fetch(automata)
          break new_state if succ.empty?
          succ.reverse_each { stack << [_1, new_state] }
        elsif automata == no_match_advanced
          stack << [start, new_state]
        elsif stack.empty? && !new_state.past_eos?
          stack << [no_match_advanced, new_state]
        end
  
        break new_state if stack.empty?
      end
  
      end_state.match_data
    end
  end
end
