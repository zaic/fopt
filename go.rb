require 'json'

require_relative 'luna/luna'
require_relative 'execution/context'
require_relative 'execution/parser'



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
                result = block = Block.new(name, parse_arguments_list(args['args'])[0])
                context.add_block block
                $stderr.puts  ' ' * recursion_level + 'struct ' + name.to_s + '(' + block.args.join(', ') + ')'
                block.body = prepare(args['body'], context, recursion_level)
                block.body.each{ |cmd| cmd.parent = block }

            when 'dfs'
                result = df = DataFragmentsDefinition.new(args['names'])
                $stderr.puts  ' ' * recursion_level + 'dfs: ' + df.names.join(', ')

            when 'exec'
                code = args['code']
                prototype = context.externs[code] if context.externs.key?(code)
                prototype = context.blocks[code] if context.blocks.key?(code)
                fail "Unable to find function '#{code}' prototype" if prototype.nil?
                output_list = prototype.args.map{ |type| type == 'name' }

                func_args, deps = *parse_arguments_list(args['args'], output_list)

                result = execute = Execute.new(args['id'], args['code'], func_args, deps)
                $stderr.puts  ' ' * recursion_level + 'exec ' + execute.code + '(' + execute.args.join(', ') + ') <' + deps.join(', ') + '>'

            when 'if'
                result = opif = OperatorIf.new(*parse_expression(args['cond']))
                $stderr.puts  ' ' * recursion_level + 'if (' + opif.condition + '), <' + opif.input_dfs_names.join(', ') + '>'
                opif.body = prepare(args['body'], context, recursion_level).each{ |cmd| cmd.parent = opif }

            when 'for'
                from = parse_expression(args['first'])
                to = parse_expression(args['last'])
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

# FixMe move to Element
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
        $stderr.puts "Processing #{block}"

        if block.kind_of?(Execute)
            $stderr.puts "  Executing #{block.code} (parent: #{block.parent}, args: #{block.args})"

            # extern function
            if context.externs.key?(block.code)
                function = context.externs[block.code]
                $stderr.puts "  Function prototype is #{function.args}"

                #resolved_args = block.args.map{ |name| find_data_fragment(block, name)}
                resolved_args = function.args.size.times.map do |i|
                    type = function.args[i]
                    name = block.args[i]

                    if type == 'name' or type == 'value'
                        # FixMe copy-paste :(
                        indexes = []
                        if name.include?('[')
                            $stderr.puts "  It's array in function args '#{name}'"
                            indexes_expr = name.gsub(/[\[\]]/, ' ').split(/\s+/)
                            name = indexes_expr.shift
                            indexes = indexes_expr.map do |index_expr|
                                # FixMe replace by local_eval. or don't replace...
                                expr = block.input_dfs.select{ |var| not var.value.nil? }.map{ |var| "#{var.name} = #{var.value}; " }.join + index_expr
                                index_value = eval(expr).to_s
                                $stderr.puts "  Index calculated as '#{expr}' = '#{index_value}'"
                                index_value
                            end
                        end

                        df = find_data_fragment(block, name)
                        indexes.each{ |id| df = df[id] }
                        $stderr.puts "  TrOlolo my name is '#{df.inspect}'"
                        df

                    elsif type == 'int' or type == 'real' or type == 'string'
                        $stderr.puts "  Create stub DataFragment with value '#{name}'"
                        DataFragment.new('noname_expression', block.local_eval(name))

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
                    #df = find_data_fragment(block, block.args[i])
                    df = block.resolve_indexes(block.args[i])
                    $stderr.puts "set #{df.name} = #{df.value.to_s}"
                    df.dependents.each do |cmd|
                        cmd.dep_counter -= 1
                        $stderr.puts "relax #{cmd}, cnt = #{cmd.dep_counter}" # ToDo delete
                        ready_to_process << cmd if cmd.dep_counter == 0
                    end
                end

            # inner struct function
            elsif context.blocks.key?(block.code)
                # FixMe implement

            # ooops...
            else
                fail "Function '#{block.code}' doesn't defined"
            end


        else
            block.body.each do |command|
                if command.kind_of?(DataFragmentsDefinition)
                    $stderr.puts "  Defining variables #{command.names.join(', ')}"
                    command.names.each{ |name| block.data_fragments[name] = DataFragment.new(name) }

                else
                    $stderr.puts '  Opa, found class: ' + command.class.to_s
                    command.input_dfs_names.each do |arg_name|
                        arg_df = command.resolve_indexes(arg_name)

                        if arg_df.value.nil?
                            command.dep_counter += 1
                            arg_df.dependents << command
                        end

                        command.input_dfs << arg_df
                    end
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