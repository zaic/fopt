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
        arg_dfs[0].value = 5 if !arg_dfs.empty?
    end
end