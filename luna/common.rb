class Element
    attr_accessor :parent, :data_fragments

    # dependencies
    attr_accessor :input_dfs       # input data fragments
    attr_accessor :dep_counter     # unresolved dependencies counter
    attr_reader   :input_dfs_names # names of input_dfs

    def initialize(input_dfs_names = [])
        @parent = nil
        @data_fragments = {}

        @input_dfs = []
        @dep_counter = 0
        @input_dfs_names = input_dfs_names
    end

    def copy!(from)
        @parent = from.parent
        @data_fragments = from.data_fragments.dup

        @input_dfs = from.input_dfs.dup
        @dep_counter = from.dep_counter
        @input_dfs_names = from.input_dfs_names.dup
    end

    def copy
        res = Element.new
        res.copy!(self)
        res
    end

    def local_eval(expr)
        expr = input_dfs.map{ |var| "#{var.name} = #{var.value}; " }.join + expr
        eval(expr)
    end
end