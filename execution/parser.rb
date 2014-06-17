# Parse JSON condition expression and return pair<ruby_expression_string, list_of_dependencies>
def parse_expression(cond)
    if %w(+ - * / % && || < > <= >= != ==).include?(cond['type']) # op, op, operator
        op_left = parse_expression(cond['operands'][0])
        op_right = parse_expression(cond['operands'][1])
        ["(#{op_left[0]}#{cond['type']}#{op_right[0]})", op_left[1] | op_right[1]]

    elsif cond['type'] =~ /.const/ # iconst, fconst, sconst, etc...
        ["(#{cond['value']})", []]

    elsif cond['type'] == 'id' # data fragment
        # get variable name
        var_name = cond['ref'][0]
        # other arguments correspond to array indexes
        res = cond['ref'][1..-1].map{ |var| parse_expression(var) }.reduce([var_name, []]){ |sum, pair| [sum[0] + '[' + pair[0] + ']', sum[1] | pair[1]] }
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
def parse_arguments_list(json, output_variables = nil)
    # ToDo: rename ;)
    target_variables = []
    res = json.map{ |arg| parse_expression(arg) }.reduce([[],[]]) do |sum, parsed_arg|
        parsed_arg[0] = parsed_arg[0][1...-1]
        target_variables << parsed_arg[0]
        [sum[0] | [parsed_arg[0]], sum[1] | parsed_arg[1]]
    end
    output_variables.size.times{ |i| res[1] -= [target_variables[i]] if output_variables[i] } if output_variables # ToDo required input variable can be removed too :(
    res
end
