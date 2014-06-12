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

# Parse JSON condition expression and return pair<ruby_expression_string, list_of_dependencies>
def cond_parser(cond)
    p cond
    if %w(+ - * / % && || < > <= >= != ==).include?(cond['type']) # opa, opa, operator
        op_left = cond_parser(cond['operands'][0])
        op_right = cond_parser(cond['operands'][1])
        ["(#{op_left[0]}#{cond['type']}#{op_right[0]})", op_left[1] | op_right[1]]

    elsif cond['type'] =~ /.const/ # iconst, fconst, sconst, etc...
        ["(#{cond['value']})", []]

    elsif cond['type'] == 'id' # data fragment
        # ToDo: we need to go deeper?
        ["(#{cond['ref'][0]})", [cond['ref'][0]]]

    else
        raise "Unknown type '#{cond['type']}' in condition '#{cond}'"
    end
end

# Convert JSON to ruby expression
def args_parser(json)
    # ToDo: implement :)
    json.map{ |arg| cond_parser(arg)[0] }
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
                block.body.each{ |cmd| cmd.parent = block }

            when 'dfs'
                result = df = DataFragmentsDefinition.new(args['names'])
                $stderr.puts  ' ' * recursion_level + 'dfs: ' + df.names.join(', ')

            when 'exec'
                result = execute = Execute.new(args['id'], args['code'], args_parser(args['args']))
                $stderr.puts  ' ' * recursion_level + 'exec ' + execute.code + '(' + execute.args.join(', ') + ')'

            when 'if'
                result = opif = OperatorIf.new(*cond_parser(args['cond']))
                $stderr.puts  ' ' * recursion_level + 'if (' + opif.condition + '), <' + opif.input_dfs_names.join(', ') + '>'
                opif.body = prepare(args['body'], context, recursion_level)
                opif.body.each{ |cmd| cmd.parent = opif }

            else
                raise "Unknown command '#{name}' in json '#{args}'"
        end

        recursion_level -= 2
        $stderr.puts  ' ' * recursion_level + '< ' + name.to_s

        result
    end
end

def find_data_fragment(block, df_name)
    raise "Data fragment '#{df_name}' not found" if block.nil?
    return block.data_fragments[df_name] if block.data_fragments.key?(df_name)
    find_data_fragment(block.parent, df_name)
end

def execute(init_block, context)
    ready_to_process = [init_block]
    wait_for_data = []

    loop do
        break if ready_to_process.empty?
        block = ready_to_process.pop

        p "==="
        p block.class

        if block.kind_of?(Execute)
            $stderr.puts "Executing #{block.id}..."
            block.run

        else
            block.body.each do |command|
                if command.kind_of?(DataFragmentsDefinition)
                    $stderr.puts "Defining variables #{command.names.join(', ')}"
                    command.names.each{ |name| block.data_fragments[name] = DataFragment.new(name) }

                else
                    $stderr.puts 'opa, class: ' + command.class.to_s
                    command.input_dfs_names.each do |arg_name|
                        arg_df = find_data_fragment(command, arg_name)
                        command.dep_counter += 1 if arg_df.nil?
                        command.input_dfs << arg_df
                    end
                    p command.input_dfs
                    que = (command.dep_counter == 0 ? ready_to_process : wait_for_data)
                    que << command
                end
            end
        end
    end
end

if ARGV.empty?
    $stderr.puts "Usage: #{__FILE__} input.txt"
    exit
end

program = JSON.parse(File.read(ARGV.first))

context = Context.new
prepare(program, context)
$stderr.puts "\nParsed\n\n"
execute(context.blocks['main'], context)