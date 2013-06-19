#!/usr/bin/env ruby

# Spellchecker

# Write a program that reads a large list of English words (e.g. from /usr/share/dict/words on a unix system) into memory, and then reads words from stdin, and prints either the best spelling suggestion, or "NO SUGGESTION" if no suggestion can be found. The program should print ">" as a prompt before reading each word, and should loop until killed.

# Your solution should be faster than O(n) per word checked, where n is the length of the dictionary. That is to say, you can't scan the dictionary every time you want to spellcheck a word.

# For example:

# > sheeeeep
# sheep
# > peepple
# people
# > sheeple
# NO SUGGESTION
# The class of spelling mistakes to be corrected is as follows:

# Case (upper/lower) errors: "inSIDE" => "inside"
# Repeated letters: "jjoobbb" => "job"
# Incorrect vowels: "weke" => "wake"
# Any combination of the above types of error in a single word should be corrected (e.g. "CUNsperrICY" => "conspiracy").

# If there are many possible corrections of an input word, your program can choose one in any way you like. It just has to be an English word that is a spelling correction of the input by the above rules.

  class String

    # ancient semitic languages had no vowels
    # this variation also prevents serial duplicates
    def to_sem
      self.gsub(/[a e i o u y]+/,'').
        split('').
        inject('') do |m,x|
          m << x if m[-1] != x
          m
        end
    end

    def to_sa
      self.split('').map(&:to_sym)
    end

  end

  class Trie
    def initialize
      @root = Hash.new
    end

    def build(stringy)
      str = stringy.to_sem.to_sa
      node = @root
      str.each do |ch|
        node[ch] ||= Hash.new
        node = node[ch]
      end
      node[:end] = stringy
    end

    def find(stringy)
      str = stringy.to_sem.to_sa
      node = @root
      str.each do |ch|
        return nil unless node = node[ch]
      end
      node[:end]
    end
  end

@dictionary = Trie.new
file = ARGV[0] || "/usr/share/dict/words"

if file == 'help'
  puts "usage: spellcheck.rb [dictionary-file]"
  exit
end

puts "building dictionary from #{file}"


File.open(file).readlines.each do |x|
  @dictionary.build(x.downcase.chomp)
end

loop do
  print "> "
  s = gets.chomp
  puts @dictionary.find(s) || "NO SUGGESTION"
end

