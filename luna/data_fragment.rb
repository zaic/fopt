require_relative 'common.rb'

class DataFragment < Element
    attr_reader :names

    def initialize(names)
        @names = names.to_a
    end
end