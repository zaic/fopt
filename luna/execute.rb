require_relative 'common'

class Execute < Element
    attr_reader :id, :code, :args

    def initialize(id, code, args)
        super()
        @id = id.to_s
        @code = code.to_s
        @args = args.to_a
    end

    def run(arg_dfs)
        arg_dfs[0].value = (rand * 3).to_i if !arg_dfs.empty?
    end
end