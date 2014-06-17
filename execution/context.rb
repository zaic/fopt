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
end

