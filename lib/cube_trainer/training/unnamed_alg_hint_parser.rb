# frozen_string_literal: true

require 'twisty_puzzles'
require 'cube_trainer/training/alg_hinter'
require 'cube_trainer/training/alg_set_reverse_engineer'
require 'cube_trainer/training/hint_parser'

module CubeTrainer
  module Training
    # Parses hints for an alg set where we don't have alg names in the alg sheet,
    # but we do know for each alg what it's supposed to do and hence we can reverse
    # engineer which alg is which (e.g. for corner twists).
    class UnnamedAlgHintParser < HintParser
      include Core

      def initialize(name, input_items, options)
        @name = name
        @input_items = input_items
        @options = options
        @verbose = options.verbose
      end

      attr_reader :name, :verbose

      def engineer
        @engineer ||=
          AlgSetReverseEngineer.new(@input_items, @options.color_scheme, @options.cube_size)
      end

      def parse_hints_internal(raw_hints)
        keyed_algs = {}
        extract_commutators(raw_hints).each do |comm|
          key = engineer.find_stuff(comm.algorithm)
          keyed_algs[key] = comm if key
        end
        keyed_algs
      end

      def extract_commutators(raw_hints)
        comms = []
        raw_hints.each do |row|
          row.each do |cell|
            next if cell.blank?

            comm = parse_commutator(cell, false)
            # Ignore very short algorithms. They are never valid and they can be things like piece
            # types.
            comms.push(comm) unless comm.algorithm.length <= 3
          end
        end
        comms
      end

      def hinter_class
        AlgHinter
      end

      def self.maybe_parse_hints(name, input_items, verbose)
        new(name, input_items, verbose).maybe_parse_hints
      end
    end
  end
end
