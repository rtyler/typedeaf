require 'concurrent'

require 'typedeaf/arguments'
require 'typedeaf/errors'

module Typedeaf
  module ClassMethods
    def default(value, *types)
      return Typedeaf::Arguments::DefaultArgument.new(value, *types)
    end

    def promise(method_sym,
                params={},
                method_builder=:define_method,
                &block)

      future(method_sym,
             params,
             method_builder,
             primitive=Concurrent::Promise,
             &block)
    end

    def future(method_sym,
               params={},
               method_builder=:define_method,
               primitive=Concurrent::Future,
               &block)

      __typedeaf_validate_body_for(method_sym, block)
      __typedeaf_method_parameters__[method_sym] = params

      send(method_builder, method_sym) do |*args, &blk|
        __typedeaf_handle_nested_block(params, args, blk)
        __typedeaf_handle_default_parameters(params, args)
        __typedeaf_validate_positionals(params, args)

        stack_element =  [method_sym, __typedeaf_validate_types(params, args)]
        primitive.new do
          # We're inserting into the varstack within the future to make sure
          # we're using the right thread+instance combination
          __typedeaf_varstack__ << stack_element
          begin
            instance_exec(&block)
          ensure
            __typedeaf_varstack__.pop
          end
        end.execute
      end

      return self
    end

    def define(method_sym, params={}, method_builder=:define_method, &block)
      params = params.freeze
      __typedeaf_validate_body_for(method_sym, block)
      __typedeaf_method_parameters__[method_sym] = params

      send(method_builder, method_sym) do |*args, &blk|
        # Optimization, if we're a parameter-less method, just pass right
        # through without any checks whatsoever
        if params.empty?
          return instance_exec(&block)
        end

        __typedeaf_handle_nested_block(params, args, blk)
        __typedeaf_handle_default_parameters(params, args)
        __typedeaf_validate_positionals(params, args)

        __typedeaf_varstack__ << [method_sym,
                                  __typedeaf_validate_types(params, args)]

        begin
          instance_exec(&block)
        ensure
          __typedeaf_varstack__.pop
        end
      end

      return self
    end

    def class_define(method_sym, params={}, &block)
      define(method_sym, params, :define_singleton_method, &block)
    end

    def class_future(method_sym, params={}, &block)
      future(method_sym, params, :define_singleton_method, &block)
    end

    def class_promise(method_sym, params={}, &block)
      promise(method_sym, params, :define_singleton_method, &block)
    end

    def __typedeaf_method_parameters__
      if @__typedeaf_method_parameters__.nil?
        @__typedeaf_method_parameters__ = {}
      end

      return @__typedeaf_method_parameters__
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
