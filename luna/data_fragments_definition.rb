require_relative 'common.rb'

class DataFragmentsDefinition < Element
    attr_reader :names

    def initialize(names)
        super()
        @names = names.to_a
    end

    def copy
        res = DataFragmentsDefinition.new(@names.dup)
        res.copy!(self)
        res
    end
end

class DataFragment < Element
    attr_reader :name
    attr_accessor :value
    attr_accessor :dependents

    def initialize(name, value = nil)
        super()
        @name, @value = name, value
        @dependents = []
    end

    def copy
        res = DataFragment.new(@name)
        res.copy!(self)
        res.value = @value.dup
        res.dependents = @dependents.dup
        res
    end
end