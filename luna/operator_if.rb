require_relative 'common'

class OperatorIf < Element
    attr_reader :condition

    def initialize(condition, dependencies)
        super(dependencies)
        @condition = condition
        @body = []
    end

    def body=(cmds)
        @body = cmds
    end

    def body
        # ToDo check variable type
        cond_expr = input_dfs.map{ |var| "#{var.name} = #{var.value}; " }.join + @condition
        $stderr.puts "Check condition '#{cond_expr}'"
        eval(cond_expr, nil) ? @body : []
    end
end