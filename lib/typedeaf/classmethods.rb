require 'concurrent'

require 'typedeaf/arguments'
require 'typedeaf/errors'

module Typedeaf
  module ClassMethods
    def default(value, *types)
      return Typedeaf::Arguments::DefaultArgument.new(value, *types)
    end

    def promise(method_sym, params={}, &block)
      future(method_sym, params, primitive=Concurrent::Promise, &block)
    end

    def future(method_sym, params={}, primitive=Concurrent::Future, &block)
      __typedeaf_validate_body_for(method_sym, block)

      define_method(method_sym) do |*args, &blk|
        __typedeaf_handle_nested_block(params, args, blk)
        __typedeaf_handle_default_parameters(params, args)
        __typedeaf_validate_positionals(params, args)

        primitive.new do
          # We're inserting into the varstack within the future to make sure
          # we're using the right thread+instance combination
          __typedeaf_varstack__ << [params,
                                    __typedeaf_validate_types(params, args)]
          begin
            instance_exec(&block)
          ensure
            __typedeaf_varstack__.pop
          end
        end.execute
      end

      return self
    end

    def define(method_sym, params={}, &block)
      __typedeaf_validate_body_for(method_sym, block)

      define_method(method_sym) do |*args, &blk|
        __typedeaf_handle_nested_block(params, args, blk)
        __typedeaf_handle_default_parameters(params, args)
        __typedeaf_validate_positionals(params, args)

        __typedeaf_varstack__ << [params,
                                  __typedeaf_validate_types(params, args)]

        begin
          instance_exec(&block)
        ensure
          __typedeaf_varstack__.pop
        end
      end

      return self
    end

    private

    def __typedeaf_validate_body_for(method, block)
      if block.nil?
        raise MissingMethodException,
            "You must provide a block for the #{method} body"
      end
    end

  end
end