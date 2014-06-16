require_relative 'common'
require_relative 'block'

class OperatorFor < Element
    attr_reader :counter_name, :counter_from_expr, :counter_to_expr

    def initialize(name, from, to, dependencies)
        super(dependencies)
        @counter_name, @counter_from_expr, @counter_to_expr = name.to_s, from.to_s, to.to_s
        @body = []
        @counter_value = nil
    end

    def body=(cmds)
        @body = cmds
    end

    def body
        @counter_value = local_eval(@counter_from_expr).to_i if @counter_value.nil?

        res = Block.new('noname_for_block', [])
        res.parent = @parent
        res.data_fragments[@counter_name] = DataFragment.new(@counter_name, @counter_value)
        res.body = @body.map(&:copy).each{ |cmd| cmd.parent = res }

        @counter_value += 1
        counter_to_value = local_eval(@counter_to_expr).to_i
        if @counter_value <= counter_to_value
            res.body << self
        end

        [res]
    end
end