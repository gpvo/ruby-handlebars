require_relative 'default_helper'

module RubyHandlebars
  module Helpers
    class IfHelper < DefaultHelper
      def self.registry_name
        'if'
      end

      def self.apply(context, condition, block, else_block, elsif_block)
        condition = !condition.empty? if condition.respond_to?(:empty?)

        if condition
          block.fn(context)
        else
          if elsif_block && !elsif_block.empty?
            matched_block = elsif_block.detect { |block|
              block.parameters.eval(context)
            }

            if matched_block
              return matched_block.fn(context)
            end
          end
          if else_block
            else_block.fn(context)
          else
            ""
          end
        end
      end
    end
  end
end
