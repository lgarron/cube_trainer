# frozen_string_literal: true

require 'cube_trainer/core/part_cycle_factory'
require 'cube_trainer/letter_pair_helper'
require 'cube_trainer/training/input_sampler'
require 'cube_trainer/training/disjoint_union_alg_set'
require 'cube_trainer/training/commutator_hint_parser'
require 'cube_trainer/letter_pair_sequence'
require 'cube_trainer/training/no_hinter'
require 'cube_trainer/training/sequence_hinter'
require 'cube_trainer/training/letter_pair_alg_set'
require 'cube_trainer/utils/array_helper'

module CubeTrainer; module Training
  # Module containing useful methods for various sets of corner twists.
  module CornerTwistSetsHelper
    ORIENTATION_FACES = [Core::Face::U, Core::Face::D].freeze

    def orientation_face(part)
      faces = ORIENTATION_FACES.select { |f| part.face_symbols.include?(f.face_symbol) }
      unless faces.length == 1
        raise "Couldn't determine unique orientation face for #{part}: #{faces}"
      end

      faces.first
    end

    def rotate_orientation_face_up(part)
      part.rotate_face_up(orientation_face(part))
    end
  end

  # Class that generates input items for floating corner 2 twists.
  class FloatingCorner2Twists < LetterPairAlgSet
    include CornerTwistSetsHelper

    PART_TYPE = Core::Corner

    def initialize(result_model, options)
      super
      @hinter = NoHinter.new(input_items.map(&:representation))
    end

    attr_reader :hinter

    def goal_badness
      1.5
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def generate_input_items
      cube_state = @color_scheme.solved_cube_state(options.cube_size)
      part_cycle_factory = Core::PartCycleFactory.new(options.cube_size, 0)
      non_buffer_corners = PART_TYPE::ELEMENTS.reject { |c| c.turned_equals?(buffer) }
      correctly_oriented_corners =
        non_buffer_corners.select do |c|
          ORIENTATION_FACES.include?(c.solved_face)
        end
      two_twists =
        correctly_oriented_corners.permutation(2).map do |c1, c2|
          twisted_corner_pair = [c1.rotate_by(1), c2.rotate_by(2)]
          letter_pair = LetterPair.new(twisted_corner_pair.map { |c| letter_scheme.letter(c) }.sort)
          twist_sticker_cycles = part_cycle_factory.multi_corner_twist([c1]) +
                                 part_cycle_factory.multi_corner_twist([c2]).inverse
          twisted_cube_state = twist_sticker_cycles.apply_to_dupped(cube_state)
          InputItem.new(letter_pair, twisted_cube_state)
        end
      buffer_twist = part_cycle_factory.multi_corner_twist([buffer])
      buffer_twist.apply_to(cube_state)
      ccw_twists =
        correctly_oriented_corners.map do |c|
          twisted_corner = c.rotate_by(1)
          letter_pair = LetterPair.new([letter_scheme.letter(twisted_corner)])
          twist_sticker_cycles = part_cycle_factory.multi_corner_twist([c]).inverse
          twisted_cube_state = twist_sticker_cycles.apply_to_dupped(cube_state)
          InputItem.new(letter_pair, twisted_cube_state)
        end
      buffer_twist.apply_to(cube_state)
      cw_twists =
        correctly_oriented_corners.map do |c|
          twisted_corner = c.rotate_by(2)
          letter_pair = LetterPair.new([letter_scheme.letter(twisted_corner)])
          twist_sticker_cycles = part_cycle_factory.multi_corner_twist([c])
          twisted_cube_state = twist_sticker_cycles.apply_to_dupped(cube_state)
          InputItem.new(letter_pair, twisted_cube_state)
        end
      two_twists + cw_twists + ccw_twists
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize
  end

  # Class that generates input items for floating corner 2 twists and 3 twists.
  class FloatingCorner2TwistsAnd3Twists < DisjointUnionLetterPairAlgSet
    def initialize(results_model, options)
      super(
results_model, options, FloatingCorner2Twists.new(results_model, options),
            Corner3Twists.new(results_model, options))
    end
  end

  # Class that generates input items for corner twists plus parities.
  class CornerTwistsPlusParities < LetterPairAlgSet
    include CornerTwistSetsHelper

    PART_TYPE = Core::Corner

    def initialize(result_model, options)
      super
      corner_options = corner_options(options)
      corner_results = results_for_options(result_model, corner_options)
      corner_hinter = CommutatorHintParser.maybe_parse_hints(PART_TYPE, corner_options)

      parity_options = corner_options(options)
      parity_results = results_for_options(result_model, corner_options)
      parity_hinter = CommutatorHintParser.maybe_parse_hints(PART_TYPE, parity_options)

      @hinter = CornerTwistPlusParityHinter.new(
        corner_results, parity_results, corner_hinter,
        parity_hinter, options
      )
    end

    def corner_options(options)
      corner_options = options.dup
      corner_options.commutator_info = CommutatorOptions::COMMUTATOR_TYPES[:corners] || raise
      corner_options.picture = false
      corner_options
    end

    def parity_options(options)
      parity_options = options.dup
      parity_options.commutator_info =
        CommutatorOptions::COMMUTATOR_TYPES[:corner_parities] || raise
      parity_options.picture = false
      parity_options
    end

    def results_for_options(result_model, options)
      result_model.result_persistence.load_results(
        BufferHelper.mode_for_options(options)
      )
    end

    attr_reader :hinter

    def goal_badness
      2.0
    end

    def generate_letter_pairs
      non_buffer_corners = PART_TYPE::ELEMENTS.reject { |c| c.turned_equals?(buffer) }
      incorrectly_oriented_corners =
        non_buffer_corners.reject do |c|
          ORIENTATION_FACES.include?(c.solved_face)
        end
      parity_twist_combinations =
        non_buffer_corners.product(incorrectly_oriented_corners).reject do |parity, twist|
          parity.turned_equals?(twist)
        end
      parity_twist_combinations.map do |targets|
        LetterPairSequence.new(targets.map { |t| LetterPair.new([letter_scheme.letter(t)]) })
      end
    end

    # Class that creates hints for corner twists plus parities.
    class CornerTwistPlusParityHinter < HeterogenousSequenceHinter
      include CornerTwistSetsHelper
      include Utils::ArrayHelper

      def initialize(corner_results, parity_results, corner_hinter, parity_hinter, options)
        super(options.cube_size, [corner_results, parity_results], [corner_hinter, parity_hinter])
        @letter_scheme = options.letter_scheme
      end

      # rubocop:disable Metrics/AbcSize
      def generate_combinations(letter_sequence)
        raise ArgumentError unless letter_sequence.letter_pairs.length == 2

        parity_letter_pair = letter_sequence.letter_pairs.first
        parity_letter = only(parity_letter_pair.letters)
        twist_letter_pair = letter_sequence.letter_pairs.last
        twist_letter = only(twist_letter_pair.letters)
        twisted_part = @letter_scheme.for_letter(PART_TYPE, twist_letter)
        solved_twist_part = rotate_orientation_face_up(twisted_part)
        Array.new(Core::Corner::FACES) do |rot|
          twist_entry_letter = @letter_scheme.letter(twisted_part.rotate_by(rot))
          twist_exit_letter = @letter_scheme.letter(solved_twist_part.rotate_by(rot))
          comm = LetterPair.new([parity_letter, twist_entry_letter])
          parity = LetterPair.new([twist_exit_letter])
          [comm, parity]
        end
      end
      # rubocop:enable Metrics/AbcSize
    end
  end

  # Class that generates input items for corner 3 twists.
  class Corner3Twists < LetterPairAlgSet
    include CornerTwistSetsHelper

    PART_TYPE = Core::Corner

    def initialize(result_model, options)
      super
      corner_options = options.dup
      corner_options.commutator_info = CommutatorOptions::COMMUTATOR_TYPES[:corners] || raise
      corner_options.picture = false
      corner_results = result_model.result_persistence.load_results(
        BufferHelper.mode_for_options(corner_options)
      )
      corner_hinter = CommutatorHintParser.maybe_parse_hints(PART_TYPE, corner_options)
      @hinter = Corner3TwistHinter.new(corner_results, corner_hinter, options)
    end

    attr_reader :hinter

    def goal_badness
      2.0
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def generate_input_items
      cube_state = @color_scheme.solved_cube_state(options.cube_size)
      part_cycle_factory = Core::PartCycleFactory.new(options.cube_size, 0)
      non_buffer_corners = PART_TYPE::ELEMENTS.reject { |c| c.turned_equals?(buffer) }
      correctly_oriented_corners =
        non_buffer_corners.select do |c|
          ORIENTATION_FACES.include?(c.solved_face)
        end
      buffer_twist = part_cycle_factory.multi_corner_twist([buffer])
      1.upto(2).collect_concat do |twist_number|
        buffer_twist.apply_to(cube_state)
        correctly_oriented_corners.combination(2).collect_concat do |c1, c2|
          twisted_corner_pair = [c1.rotate_by(twist_number), c2.rotate_by(twist_number)]
          letter_pair = LetterPair.new(twisted_corner_pair.map { |c| letter_scheme.letter(c) }.sort)
          twist_sticker_cycles = part_cycle_factory.multi_corner_twist([c1, c2])
          twist_sticker_cycles = twist_sticker_cycles.inverse if twist_number == 2
          twisted_cube_state = twist_sticker_cycles.apply_to_dupped(cube_state)
          InputItem.new(letter_pair, twisted_cube_state)
        end
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize
    end

    # Class that creates hints for corner 3 twists.
    class Corner3TwistHinter < HomogenousSequenceHinter
      include CornerTwistSetsHelper

      # Note that this should be the results for corner comms, not for corner 3 twists.
      def initialize(corner_results, corner_hinter, options)
        super(options.cube_size, corner_results, corner_hinter)
        @letter_scheme = options.letter_scheme
      end

      def rotate_other_face_up(part)
        part.rotate_other_face_up(orientation_face(part))
      end

      def rotate_comm_target(comm, target_index, rotation)
        raise ArgumentError unless comm.length == 2
        raise ArgumentError unless [0, 1].include?(target_index)

        comm.map.with_index do |c, i|
          if i == target_index
            c.rotate_by(rotation)
          else
            c
          end
        end
      end

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      def generate_directed_solutions(parts)
        raise unless parts.length == 2

        first_corner, second_corner = parts

        # We define one solution explicitly
        solution_corners = [
          # Parts for first comm
          [first_corner, second_corner],
          # Parts for second comm
          [rotate_orientation_face_up(second_corner), rotate_other_face_up(first_corner)]
        ]

        # Now we generate additional solutions by rotating both colors in one direction.
        extended_solutions =
          Array.new(Core::Corner::FACES) do |rot|
            solution_corners.map do |comm|
              comm.map { |p| p.rotate_by(rot) }
            end
          end

        # Now we generate even more additional solutions by rotating the second corner of the first
        # comm and the first corner of the second comm in opposite directions.
        extended_solutions =
          Core::Corner::FACES.times.collect_concat do |rot|
            extended_solutions.map do |solution|
              raise unless solution.length == 2

              first_comm, second_comm = solution
              [
                rotate_comm_target(first_comm, 1, rot),
                rotate_comm_target(second_comm, 0, rot)
              ]
            end
          end

        # Now we generate letter pairs
        extended_solutions.map do |s|
          s.map { |comm| LetterPair.new(comm.map { |p| @letter_scheme.letter(p) }) }
        end
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize

      def generate_combinations(letter_pair)
        pieces = letter_pair.letters.map { |l| @letter_scheme.for_letter(PART_TYPE, l) }
        generate_directed_solutions(pieces) + generate_directed_solutions(pieces.reverse)
      end
    end
  end

  # Class that generates input items for floating edge flips.
  class FloatingEdgeFlips < LetterPairAlgSet
    PART_TYPE = Core::Edge

    def initialize(result_model, options)
      super
      @hinter = NoHinter.new(input_items.map(&:representation))
    end

    attr_reader :hinter

    def goal_badness
      2.0
    end

    def generate_letter_pairs
      edge_letters = PART_TYPE::ELEMENTS.map do |c|
        c.rotations.map { |r| letter_scheme.letter(r) }.min
      end.uniq.sort
      edge_letters.combination(2).map { |cs| LetterPair.new(cs) }
    end
  end

  # Class that generates input items for commutators.
  class CommutatorSet < LetterPairAlgSet
    # If restrict_letters is not nil, only commutators for those letters are used.
    def initialize(results_model, options)
      super
      @hinter = CommutatorHintParser.maybe_parse_hints(self.class::PART_TYPE, options)
    end

    attr_reader :hinter
  end

  # Class that generates input items for corner commutators.
  class CornerCommutators < CommutatorSet
    PART_TYPE = Core::Corner

    def generate_letter_pairs
      letter_pairs_for_piece - rotations
    end

    def goal_badness
      1.0
    end
  end

  # Class that generates input items for edge commutators.
  class EdgeCommutators < CommutatorSet
    PART_TYPE = Core::Edge

    def generate_letter_pairs
      letter_pairs_for_piece - rotations
    end

    def goal_badness
      1.0
    end
  end

  # Class that generates input items for wing commutators.
  class WingCommutators < CommutatorSet
    PART_TYPE = Core::Wing

    def generate_letter_pairs
      letter_pairs_for_piece - rotations
    end

    def goal_badness
      2.0
    end
  end

  # Class that generates input items for X center commutators.
  class XCenterCommutators < CommutatorSet
    PART_TYPE = Core::XCenter

    def generate_letter_pairs
      letter_pairs_for_piece - neighbors
    end

    def goal_badness
      4.0
    end
  end

  # Class that generates input items for T center commutators.
  class TCenterCommutators < CommutatorSet
    PART_TYPE = Core::TCenter

    def generate_letter_pairs
      letter_pairs_for_piece - neighbors
    end

    def goal_badness
      4.0
    end
  end

  # Class that generates input items for corner parities.
  class CornerParities < LetterPairAlgSet
    PART_TYPE = Core::Corner

    def initialize(result_model, options)
      super
      @hinter = NoHinter.new(input_items.map(&:representation))
    end

    attr_reader :hinter

    def goal_badness
      2.0
    end

    def generate_letter_pairs
      non_buffer_corners = PART_TYPE::ELEMENTS.reject { |c| c.turned_equals?(buffer) }
      non_buffer_corners.map { |c| LetterPair.new([letter_scheme.letter(c)]) }
    end
  end
end; end
