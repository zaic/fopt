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

    def find_data_fragment(name)
        return data_fragments[name] if data_fragments.key?(name)
        raise "Data fragment '#{name}' not found" if parent.nil?
        parent.find_data_fragment(name)
    end

    # ToDo rename
    def resolve_indexes(name)
        indexes = []
        if name.include?('[')
            $stderr.puts "  It's array '#{name}'"
            indexes_expr = name.gsub(/[\[\]]/, ' ').split(/\s+/)
            name = indexes_expr.shift
            $stderr.puts "  arg = '#{name}', inds = '#{indexes_expr}'"
            indexes = indexes_expr.map do |index_expr|
                # FixMe replace by local_eval. or don't replace...
                expr = input_dfs.select{ |var| not var.value.nil? }.map{ |var| "#{var.name} = #{var.value}; " }.join + index_expr
                index_value = eval(expr).to_s
                $stderr.puts "    Index calculated as '#{expr}' = '#{index_value}'"
                index_value
            end
        end

        df = self.find_data_fragment(name)
        indexes.each{ |id| df = df[id] }
        $stderr.puts "  PyschOlolo my name is '#{df.inspect}'"

        df
    end
end