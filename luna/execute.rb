require_relative 'common'

class Execute < Element
    attr_reader :id, :code, :args

    def initialize(id, code, args, deps)
        super(deps)
        @id = id.to_s
        @code = code.to_s
        @args = args.to_a
    end

    def run(arg_dfs)
        case @code
            when 'init_n'
                arg_dfs[0].value = (rand * 3).to_i if !arg_dfs.empty?

            when 'init_arr'
                arg_dfs[0].value = [1, 1, 2, 3, 5, 8] if !arg_dfs.empty?

            when 'init_random_value'
                # arg_dfs.each{ |arg| puts "#{arg.name} = #{arg.value}" }
                arg_dfs.each{ |arg| arg.value = (rand * 3).to_i }

            else
                $stderr.puts "given arguments = #{arg_dfs.map{ |arg| "#{arg.name} = #{arg.value.to_s}" }.join(', ')}"
        end

    end

    def copy
        res = Execute.new(@id.dup, @code.dup, @args.dup, [])
        res.copy!(self)
        res
    end
end