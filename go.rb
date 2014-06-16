require 'json'

require_relative 'luna/luna'

class Context
    def initialize
        @externs = {}
        @blocks = {}
    end

    attr_accessor :externs, :blocks

    def add_extern(extern)
        raise "Redefinition: extern '#{extern.name}' already exists" if @externs.key?(extern.name)
        raise "Redefinition: struct '#{extern.name}' already exists" if @blocks.key?(extern.name)
        @externs[extern.name] = extern
    end

    def add_block(struct)
        raise "Redefinition: extern '#{struct.name}' already exists" if @externs.key?(struct.name)
        raise "Redefinition: struct '#{struct.name}' already exists" if @blocks.key?(struct.name)
        @blocks[struct.name] = struct
    end

    def step_into

    end

    def step_out

    end
end

# Parse JSON condition expression and return pair<ruby_expression_string, list_of_dependencies>
def cond_parser(cond)
    if %w(+ - * / % && || < > <= >= != ==).include?(cond['type']) # op, op, operator
        op_left = cond_parser(cond['operands'][0])
        op_right = cond_parser(cond['operands'][1])
        ["(#{op_left[0]}#{cond['type']}#{op_right[0]})", op_left[1] | op_right[1]]

    elsif cond['type'] =~ /.const/ # iconst, fconst, sconst, etc...
        ["(#{cond['value']})", []]

    elsif cond['type'] == 'id' # data fragment
        # get variable name
        var_name = cond['ref'][0]
        # other arguments correspond to array indexes
        res = cond['ref'][1..-1].map{ |var| cond_parser(var) }.reduce([var_name, []]){ |sum, pair| [sum[0] + '[' + pair[0] + ']', sum[1] | pair[1]] }
        # add itself ot dependencies
        res[1] |= [res[0]]
        # add braces around expression
        res[0] = "(#{res[0]})"
        # and return result
        res

    else
        fail "Unknown type '#{cond['type']}' in condition '#{cond}'"
    end
end

# Convert JSON to ruby expression
def args_parser(json)
    # ToDo: rename ;)
    json.map{ |arg| cond_parser(arg) }.reduce([[],[]]){ |sum, parg| [sum[0] | [parg[0]], sum[1] | parg[1]] }
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
                result = block = Block.new(name, args_parser(args['args'])[0])
                context.add_block block
                $stderr.puts  ' ' * recursion_level + 'struct ' + name.to_s + '(' + block.args.join(', ') + ')'
                block.body = prepare(args['body'], context, recursion_level)
                block.body.each{ |cmd| cmd.parent = block }

            when 'dfs'
                result = df = DataFragmentsDefinition.new(args['names'])
                $stderr.puts  ' ' * recursion_level + 'dfs: ' + df.names.join(', ')

            when 'exec'
                func_args, deps = *args_parser(args['args'])
                result = execute = Execute.new(args['id'], args['code'], func_args, deps)
                $stderr.puts  ' ' * recursion_level + 'exec ' + execute.code + '(' + execute.args.join(', ') + ') <' + deps.join(', ') + '>'

            when 'if'
                result = opif = OperatorIf.new(*cond_parser(args['cond']))
                $stderr.puts  ' ' * recursion_level + 'if (' + opif.condition + '), <' + opif.input_dfs_names.join(', ') + '>'
                opif.body = prepare(args['body'], context, recursion_level).each{ |cmd| cmd.parent = opif }

            when 'for'
                from = cond_parser(args['first'])
                to = cond_parser(args['last'])
                result = opfor = OperatorFor.new(args['var'], from[0], to[0], from[1] | to[1])
                $stderr.puts  ' ' * recursion_level + "for (#{opfor.counter_name} = #{opfor.counter_from_expr} .. #{opfor.counter_to_expr}) <" + opfor.input_dfs_names.join(', ') + '>'
                opfor.body = prepare(args['body'], context, recursion_level).each{ |cmd| cmd.parent = opif }

            else
                raise "Unknown command '#{name}' in json '#{args}'"
        end

        recursion_level -= 2
        $stderr.puts  ' ' * recursion_level + '< ' + name.to_s

        result
    end
end

def find_data_fragment(block, df_name)
    # $stderr.puts "Searching for '#{df_name}' in #{block}"
    raise "Data fragment '#{df_name}' not found" if block.nil?
    return block.data_fragments[df_name] if block.data_fragments.key?(df_name)
    find_data_fragment(block.parent, df_name)
end

def execute(init_block, context)
    ready_to_process = [init_block]
    wait_for_data = [] # ToDo: remove nah?

    loop do
        break if ready_to_process.empty?
        block = ready_to_process.pop

        p "==="
        $stderr.puts "Processing #{block}"

        if block.kind_of?(Execute)
            $stderr.puts "Executing #{block.code} (parent: #{block.parent}, args: #{block.args})"

            # extern function
            if context.externs.key?(block.code)
                function = context.externs[block.code]
                $stderr.puts "Function prototype is #{function.args}"

                #resolved_args = block.args.map{ |name| find_data_fragment(block, name)}
                resolved_args = function.args.size.times.map do |i|
                    type = function.args[i]
                    name = block.args[i]

                    if type == 'name' or type == 'value'
                        find_data_fragment(block, name)
                    elsif type == 'int' or type == 'real' or type == 'string'
                        $stderr.puts "Create stub DataFragment with value '#{name}'"
                        DataFragment.new("noname_expression", block.local_eval(name))
                    else
                        fail "Unknown argument type '#{type}'"
                    end
                end
                block.run(resolved_args)
                # relax dependencies on output variables
                # ToDo: output variables

                raise "Function '#{block.code}' not found" if function.nil?
                function.args.size.times do |i|
                    next unless function.args[i] == 'name' # not output variable
                    df = find_data_fragment(block, block.args[i])
                    $stderr.puts "set #{df.name} = #{df.value.to_s}"
                    df.dependents.each do |cmd|
                        cmd.dep_counter -= 1
                        $stderr.puts "relax #{cmd}, cnt = #{cmd.dep_counter}"
                        ready_to_process << cmd if cmd.dep_counter == 0
                    end
                end

            # inner struct function
            elsif context.blocks.key?(block.code)

            # ooops...
            else
                fail "Function '#{block.code}' doesn't defined"
            end


        else
            block.body.each do |command|
                if command.kind_of?(DataFragmentsDefinition)
                    $stderr.puts "Defining variables #{command.names.join(', ')}"
                    command.names.each{ |name| block.data_fragments[name] = DataFragment.new(name) }

                else
                    $stderr.puts 'opa, class: ' + command.class.to_s
                    command.input_dfs_names.each do |arg_name|
                        # expand array indexes
                        indexes = []
                        if arg_name.include?('[')
                            $stderr.puts "It's array '#{arg_name}'"
                            indexes_expr = arg_name.gsub(/[\[\]]/, ' ').split(/\s+/)
                            arg_name = indexes_expr.shift
                            $stderr.puts "arg = '#{arg_name}', inds = '#{indexes_expr}'"
                            indexes = indexes_expr.map do |index_expr|
                                # FixMe replace by local_eval. or don't replace...
                                expr = command.input_dfs.select{ |var| not var.value.nil? }.map{ |var| "#{var.name} = #{var.value}; " }.join + index_expr
                                index_value = eval(expr).to_s
                                $stderr.puts "Index calculated as '#{expr}' = '#{index_value}'"
                                index_value
                            end
                        end
                        arg_name

                        arg_df = find_data_fragment(command, arg_name)
                        indexes.each{ |id| arg_df = arg_df[id] }
                        $stderr.puts "Ololo my name is '#{arg_df.inspect}'"

                        if arg_df.value.nil?
                            command.dep_counter += 1
                            arg_df.dependents << command
                        end

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