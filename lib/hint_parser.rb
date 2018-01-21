require 'csv'
require 'commutator'
require 'move'
require 'commutator_checker'

module CubeTrainer

  class HintParser
    def self.csv_file(part_class)
      # TODO Filename construction sucks
      "data/#{part_class.to_s}.csv"
    end
    
    def self.parse_hints(part_class, cube_size)
      # TODO do this properly
      name = part_class.name.split('::').last
      checker = CommutatorChecker.new(part_class, name, cube_size)
      hints = {}
      hint_table = CSV.read(csv_file(name))
      # TODO make this more general to figure out other types of hint tables
      parts = hint_table[0][1..-1].collect { |p| part_class.parse(p) }
      total_algs = 0
      broken_algs = 0
      hint_table[1..-1].each_with_index do |row, row_index|
        break if row.first.nil? || row.first.empty?
        part1 = part_class.parse(row.first)
        row[1..-1].each_with_index do |e, i|
          next if e.nil? || e.empty?
          part0 = parts[i]
          letter_pair = LetterPair.new([part0.letter, part1.letter])
          begin
            commutator = parse_commutator(e)
            hints[letter_pair] = commutator
            total_algs += 1
            broken_algs += 1 unless checker.check_alg(letter_pair, commutator)
          rescue CommutatorParseError => e
            raise "Couldn't parse commutator for #{letter_pair} (i.e. #{("A".."Z").to_a[i + 1]}#{row_index + 2}) couldn't be parsed: #{e}"
          end
        end
      end
      puts "#{broken_algs} broken algs of #{total_algs}." if broken_algs > 0
      hints
    end
  
    def self.maybe_create(part_class, cube_size)
      # TODO do this properly
      name = part_class.name.split('::').last
      new(if File.exists?(csv_file(name))
            parse_hints(part_class, cube_size)
          else
            {}
          end)
    end
  
    def initialize(hints)
      @hints = hints
    end
  
    def hint(letter_pair)
      @hints[letter_pair] ||= begin
                                inverse = @hints[letter_pair.inverse]
                                if inverse then inverse.inverse else nil end
                              end
    end
  end

end
