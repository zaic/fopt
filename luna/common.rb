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
        @dep_counter = input_dfs_names.count
        @input_dfs_names = input_dfs_names
    end

end