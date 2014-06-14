require_relative 'common'

class Block < Element
    attr_reader :name, :args
    attr_accessor :body

    def initialize(name, args)
        super()
        @name = name.to_s
        @args = args.to_a
    end
end