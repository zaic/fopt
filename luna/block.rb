require_relative 'common'

class Block < Element
    attr_reader :name, :args
    attr_accessor :body

    def initialize(name, args)
        @name = name.to_s
        @args = args.to_a
    end

    def body=(cmds)
        @body = cmds
    end
end