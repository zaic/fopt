require_relative 'common.rb'

class Extern < Element
    attr_reader :orig_name, :name, :args

    def initialize(orig_name, name, args)
        super()
        @orig_name = orig_name.to_s
        @name = name.to_s
        @args = args.to_a
    end

    def execute(context)
        # fork&exec
    end

    # ToDo: comparator
end