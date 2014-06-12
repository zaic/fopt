require 'json'

class Extern
    attr_reader :orig_name, :name, :args

    def initialize(orig_name, name, args)
        @orig_name = orig_name.to_s
        @name = name.to_s
        @args = args.to_a
    end

    def execute(context)
        # fork&exec
    end

    # ToDo: comparator
end

class DataFragment
    attr_reader :names

    def initialize(names)
        @names = names.to_a
    end
end

class Execute
    attr_reader :id, :code, :args

    def initialize(id, code, args)
        @id = id.to_s
        @code = code.to_s
        @args = args.to_a
    end
end

class Block
    attr_reader :name, :args
    attr_accessor :body

    def initialize(name, args)
        @name = name.to_s
        @args = args.to_a
    end

    def body=(cmds)
        @body = cmds
    end
end

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
        context.step_into
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

            else
                raise "Unknown command '#{name}' in json '#{args}'"
        end

        recursion_level -= 2
        context.step_out
        $stderr.puts  ' ' * recursion_level + '< ' + name.to_s

        result
    end
end

if ARGV.empty? then
    $stderr.puts "Usage: #{__FILE__} input.txt"
    exit
end

program = JSON.parse(File.read(ARGV.first))

context = Context.new
prepare(program, context)
