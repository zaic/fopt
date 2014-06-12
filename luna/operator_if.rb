require_relative 'common'

class OperatorIf < Element
    attr_reader :cond
    attr_accessor :body

    def initialize(cond)
        @cond = cond
        @body = []
    end
end