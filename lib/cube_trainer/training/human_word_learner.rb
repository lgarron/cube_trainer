# frozen_string_literal: true

require 'cube_trainer/console_helpers'
require 'twisty_puzzles/utils'

module CubeTrainer
  module Training
    # Learner class that prints letter pairs to the console and has the human input fitting words.
    class HumanWordLearner
      include ConsoleHelpers
      include TwistyPuzzles::Utils::StringHelper
      COMMANDS = %w[hint replace delete quit].freeze

      def initialize(hinter, results_model, options)
        @hinter = hinter
        @results_model = results_model
        @muted = options.muted
      end

      attr_reader :muted

      def display_hints(hints)
        if hints.length < 10
          puts_and_say(hints)
        else
          IO.popen('cat | less', 'w') do |io|
            io.puts(hints)
          end
        end
      end

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/CyclomaticComplexity
      def execute(input)
        puts_and_say(input)
        time_s = nil
        word = nil
        failed_attempts = 0
        start = Time.zone.now
        until !word.nil? && @hinter.good_word?(input, word)
          if !word.nil? && COMMANDS.exclude?(word)
            failed_attempts += 1
            if input.matches_word?(word)
              puts_and_say('Incorrect!', 'en')
            else
              puts_and_say('Bad word!', 'en')
            end
          end
          word = gets.chomp.downcase
          time_s = Time.zone.now - start
          case word
          when 'hint'
            # Brutal punishment for failed attempts
            # TODO: Use num_hints
            failed_attempts += 100
            hints = @hinter.hints(input.case_key)
            display_hints(hints)
          when 'delete'
            puts 'Deleting results for the last 30 seconds and exiting.'
            @results_model.delete_after_time(Time.zone.now - 30)
            exit
          when 'quit'
            exit
          end
        end
        puts "Time: #{format_time(time_s)}; Failed attempts: #{failed_attempts}; Word: #{word}"
        PartialResult.new(time_s: time_s, failed_attempts: failed_attempts, word: word)
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize
    end
  end
end
