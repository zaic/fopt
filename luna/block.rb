require_relative 'common'

class Block < Element
    attr_reader :name, :args

    def initialize(name, args)
        super()
        @name = name.to_s
        @args = args.to_a
    end

    def body=(cmds)
        @body = cmds
    end

    def body
        @body
    end
end