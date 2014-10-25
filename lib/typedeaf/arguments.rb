module Typedeaf
  module Arguments
    class DefaultArgument
      attr_reader :value, :types
      def initialize(value, *types)
        @value = value
        @types = types
      end
    end
  end
end

