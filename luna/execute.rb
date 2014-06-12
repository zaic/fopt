require_relative 'common'

class Execute < Element
    attr_reader :id, :code, :args

    def initialize(id, code, args)
        super()
        @id = id.to_s
        @code = code.to_s
        @args = args.to_a
    end

    def run
        raise "Not implemented :("
    end
end