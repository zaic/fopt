require_relative 'common'

class OperatorIf < Element
    attr_reader :cond

    def initialize(cond)
        super()
        @cond = cond
        @body = []
    end

    def body=(cmds)
        @body = cmds
    end

    def body
        []
    end
end