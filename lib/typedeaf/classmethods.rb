require 'concurrent'

require 'typedeaf/arguments'
require 'typedeaf/errors'

module Typedeaf
  module ClassMethods
    def default(value, *types)
      return Typedeaf::Arguments::DefaultArgument.new(value, *types)
    end

    def promise(method_sym, params={}, &block)
      define(method_sym, params) do
        Concurrent::Promise.new { block.call }.execute
      end
    end

    def future(method_sym, params={}, &block)
      define(method_sym, params) do
        Concurrent::Future.new { block.call }.execute
      end
    end

    def define(method_sym, params={}, &block)
      if block.nil?
        raise MissingMethodException,
            "You must provide a block for the #{method_sym} body"
      end

      define_method(method_sym) do |*args, &blk|
        # If we've been given a block, and it's in the params list properly,
        # then we should just add it to the args as a "positional" argument
        if blk && params[:block]
          args << blk
        end

        if params.keys.size > args.size
          # Check to see if we have any defaulted parameters
          params.each do |name, argument|
            # Unless it's a special kind of argument, skip it
            next unless argument.is_a? Typedeaf::Arguments::DefaultArgument

            params[name] = argument.types
            args << argument.value
          end
        end

        # Validate that we have the right number of positional arguments
        #
        # This is only really needed to make sure we're behaving the same
        # was as natively defined method would
        positional_validation!(params.keys, args)

        # We need to walk through the list of parameters and their types and
        # perform type checking on each of them
        param_indices = {}
        params.each.with_index do |(param, type), index|
          value = args[index]
          type_validation!(param, value, type)
          # Adding the index of this parameter's value to our Hash so we can
          # properly fish it back out when the method_missing magic is being
          # invoked from within the block
          param_indices[param] = value
        end
        __typedeaf_varstack__ << [params, param_indices]

        begin
          instance_exec(&block)
        ensure
          __typedeaf_varstack__.pop
        end
      end
      return self
    end
  end
end
