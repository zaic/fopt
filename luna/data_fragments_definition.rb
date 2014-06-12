require_relative 'common.rb'

class DataFragmentsDefinition < Element
    attr_reader :names

    def initialize(names)
        super()
        @names = names.to_a
    end
end

class DataFragment < Element
    attr_reader :name
    attr_accessor :value

    def initialize(name)
        super()
        @name, @value = name, nil
    end
end