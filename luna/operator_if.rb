require_relative 'common'

class OperatorIf < Element
    attr_reader :condition

    def initialize(condition, dependencies)
        super(dependencies)
        @condition = condition
        @body = []
    end

    def body=(cmds)
        @body = cmds
    end

    def body
        @body # ToDo: check condition
    end
end