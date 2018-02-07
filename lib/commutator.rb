require 'strscan'
require 'cube'
require 'move'

module CubeTrainer

  class CommutatorParseError < StandardError
  end
  
  class PureCommutator
    def initialize(first_part, second_part)
      raise ArgumentError unless first_part.is_a?(Algorithm)
      raise ArgumentError unless second_part.is_a?(Algorithm)
      @first_part = first_part
      @second_part = second_part
    end
  
    attr_reader :first_part, :second_part
  
    def eql?(other)
      self.class.equal?(other.class) && @first_part == other.first_part && @second_part == other.second_part
    end
  
    alias == eql?
  
    def hash
      [@first_part, @second_part].hash
    end
    
    def inverse
      PureCommutator.new(second_part, first_part)
    end
  
    def to_s
      "[#{@first_part}, #{@second_part}]"
    end

    def algorithm
      first_part + second_part + first_part.invert + second_part.invert
    end
  end
  
  class SetupCommutator
    def initialize(setup, pure_commutator)
      raise ArgumentError unless setup.is_a?(Algorithm)
      raise ArgumentError unless pure_commutator.is_a?(PureCommutator)
      @setup = setup
      @pure_commutator = pure_commutator
    end
  
    attr_reader :setup, :pure_commutator
  
    def eql?(other)
      self.class.equal?(other.class) && @setup == other.setup && @pure_commutator == other.pure_commutator
    end
  
    alias == eql?
  
    def hash
      [@setup, @pure_commutator].hash
    end
  
    def inverse
      SetupCommutator.new(setup, @pure_commutator.inverse)
    end
  
    def to_s
      "[#{@setup} : #{@pure_commutator}]"
    end

    def algorithm
      setup + pure_commutator.algorithm + setup.invert
    end
  end
  
  class CommutatorParser 
    def initialize(alg_string)
      @alg_string = alg_string
      @scanner = StringScanner.new(alg_string)
    end
  
    # Parses at least one move.
    def parse_moves
      moves = []
      while m = begin skip_spaces; parse_move2 end
        moves.push(m)
      end
      complain('move') if moves.empty?
      Algorithm.new(moves)
    end
  
    def complain(parsed_object)
      raise CommutatorParseError, "Couldn't parse #{parsed_object} at #{@scanner.pos} of #{@alg_string}." 
    end
  
    def parse_open_bracket
      complain('beginning of commutator') unless @scanner.getch == '['
    end
    
    def parse_close_bracket
      complain('end of commutator') unless @scanner.getch == ']'
    end
    
    def parse
      skip_spaces
      parse_open_bracket
      setup_or_first_part = parse_moves
      skip_spaces
      char = @scanner.getch
      comm = if char == ':' || char == ';'
               skip_spaces
               parse_open_bracket
               first_part = parse_moves
               skip_spaces
               complain('middle of pure commutator') unless @scanner.getch == ','
               second_part = parse_moves
               skip_spaces
               parse_close_bracket
               SetupCommutator.new(setup_or_first_part, PureCommutator.new(first_part, second_part))
             elsif char == ','
               second_part = parse_moves
               PureCommutator.new(setup_or_first_part, second_part)
             else
               complain('end of setup or middle of pure commutator') unless @scanner.eos?
             end
      skip_spaces
      parse_close_bracket
      skip_spaces
      complain('end of commutator') unless @scanner.eos?
      comm
    end
      
  
    def parse_move2
      move = @scanner.scan(MOVE_REGEXP)
      return nil unless move
      parse_move(move)
    end
  
    def skip_spaces
      @scanner.skip(/\s+/)
    end
  end
      
  def parse_commutator(alg_string)
    CommutatorParser.new(alg_string).parse
  end

end
