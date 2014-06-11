require 'json'

class Extern
    attr_reader :orig_name, :name, :args

    def initialize(orig_name, name, args)
        @orig_name = orig_name
        @name = name
        @args = args
    end
end

class Context
    attr_accessor :externs

    def initialize
        @externs = []
    end
end

def execute(program)
    program.each{ |var| p '==='; p var }
end

if ARGV.empty? then
    $stderr.puts "Usage: #{__FILE__} input.txt"
    exit
end

program = JSON.parse(File.read(ARGV.first))
p program
execute(program)