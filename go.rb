require 'json'

require_relative 'luna/luna'

class Context
    def initialize
        @externs = {}
        @blocks = {}
    end

    attr_accessor :externs, :blocks

    def add_extern(extern)
        raise "Redefinition: extern '#{extern.name}' already exists" if @externs.include?(extern)
        raise "Redefinition: extern '#{extern.name}' already exists" if @blocks.include?(extern)
        @externs[extern.name] = extern
    end

    def add_block(struct)
        # ToDo: add check
        @blocks[struct.name] = struct
    end

    def step_into

    end

    def step_out

    end
end

# Convert JSON to ruby expression
def args_parser(json)
    # ToDo: implement :)
    [json.to_s]
end

def prepare(program, context, recursion_level = 0)
    program.map do |command|
        result = nil

        name, args = (command.kind_of?(Array) ? command : ["<def:#{command['type']}>", command])
        $stderr.puts  ' ' * recursion_level + '> ' + name.to_s
        recursion_level += 2

        case args['type']
            when 'extern'
                result = extern = Extern.new(args['code'], name, args['args'].map{ |arg| arg['type']})
                context.add_extern extern
                $stderr.puts  ' ' * recursion_level + 'extern ' + name.to_s + '(' + extern.args.join(', ') + ')'

            when 'struct'
                result = block = Block.new(name, args_parser(args['args']))
                context.add_block block
                $stderr.puts  ' ' * recursion_level + 'struct ' + name.to_s + '(' + block.args.join(', ') + ')'
                block.body = prepare(args['body'], context, recursion_level)

            when 'dfs'
                result = df = DataFragment.new(args['names'])
                $stderr.puts  ' ' * recursion_level + 'dfs: ' + df.names.join(', ')

            when 'exec'
                result = execute = Execute.new(args['id'], args['code'], args_parser(args['args']))
                $stderr.puts  ' ' * recursion_level + 'exec ' + execute.code + '(' + execute.args.join(', ') + ')'

            when 'if'
                result = opif = OperatorIf.new(args_parser(args['cond']))
                $stderr.puts  ' ' * recursion_level + 'if (' + opif.cond.join(', ') + ')'
                opif.body = prepare(args['body'], context, recursion_level)

            else
                raise "Unknown command '#{name}' in json '#{args}'"
        end

        recursion_level -= 2
        $stderr.puts  ' ' * recursion_level + '< ' + name.to_s

        result
    end
end

def execute(init_block, context)
    ready_to_process = [init_block]
    wait_for_data = []

    loop do
        break if ready_to_process.empty?
        block = ready_to_process.pop

    end
end

if ARGV.empty? then
    $stderr.puts "Usage: #{__FILE__} input.txt"
    exit
end

program = JSON.parse(File.read(ARGV.first))

context = Context.new
prepare(program, context)
execute(context.blocks['main'], context)