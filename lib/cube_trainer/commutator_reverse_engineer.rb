# frozen_string_literal: true

require 'cube_trainer/letter_pair'
require 'twisty_puzzles'

module CubeTrainer
  # Class that figures out what cycle a given commutator alg performs.
  class CommutatorReverseEngineer
    def initialize(part_type, buffer, cube_size)
      raise TypeError unless part_type.is_a?(Class)
      raise TypeError unless buffer.is_a?(TwistyPuzzles::Part) && buffer.is_a?(part_type)
      raise TypeError unless cube_size.is_a?(Integer)

      @part_type = part_type
      @buffer = buffer
      @solved_positions = {}
      @state = initial_cube_state(part_type, cube_size)
      @buffer_coordinate = solved_position(@buffer, cube_size)
    end

    def initial_cube_state(part_type, cube_size)
      # We don't care much about any other pieces, so we'll just use nil
      # everywhere.
      cube_state = TwistyPuzzles::CubeState.from_stickers(cube_size, nil_stickers(cube_size))
      # We write on every sticker where it was in the initial state.
      # That way we can easily reverse engineer what a commutator does.
      part_type::ELEMENTS.each do |part|
        cube_state[solved_position(part, cube_size)] = part
      end
      cube_state
    end

    def nil_stickers(cube_size)
      TwistyPuzzles::Face::ELEMENTS.map do
        Array.new(cube_size) do
          Array.new(cube_size) do
            nil
          end
        end
      end
    end

    def solved_position(part, cube_size)
      @solved_positions[part] ||= TwistyPuzzles::Coordinate.solved_position(part, cube_size, 0)
    end

    def find_stuff(state)
      part0 = state[@buffer_coordinate]
      return if part0 == @buffer

      part1 = state[solved_position(part0, @state.n)]
      return if part1 == @buffer

      part2 = state[solved_position(part1, @state.n)]
      TwistyPuzzles::PartCycle.new([@buffer, part0, part1]) if part2 == @buffer
    end

    def find_part_cycle(alg)
      raise TypeError unless alg.is_a?(TwistyPuzzles::Algorithm)

      alg.inverse.apply_temporarily_to(@state) { |s| find_stuff(s) }
    end
  end
end
