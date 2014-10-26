require 'thread'

require 'typedeaf/arguments'
require 'typedeaf/errors'

  module Typedeaf
    module InstanceMethods
    def method_missing(sym, *args)
      # We only want to peek at the stack if we have no args (i.e. not trying
      # to make a method call
      if args.empty? && !(__typedeaf_varstack__.empty?)
        params, values = __typedeaf_varstack__.last
        # The top of our stack contains something that we want
        return values[sym] if params[sym]
      end

      return super
    end

    private

    # Access the current thread's and instance's varstack
    #
    # Since we're inside of an object instance already, we should make sure
    # that we can isolate the method's varstack for our current thread and
    # instance together.
    #
    # Instaed of using a thread local by itself, which would not provide the
    # cross-object isolation, and instead of using just an instance variable,
    # which would require thread-safety locks, serializing all calls into and
    # out of the instance
    #
    # @return [Array] variable stack
    def __typedeaf_varstack__
      varstack_id = "typedeaf_varstack_#{self.object_id}".to_sym
      if Thread.current[varstack_id].nil?
        Thread.current[varstack_id] = []
      end
      return Thread.current[varstack_id]
    end

    # Determine whether the supplied value is an instance of the given class
    #
    # @param [Object] value
    # @param [Class] type Any class
    def __typedeaf_valid_type?(value, type)
      return value.is_a? type
    end

    # Valida
    def __typedeaf_validate_types(parameters, args)
      # We need to walk through the list of parameters and their types and
      # perform type checking on each of them
      parameter_indices = {}
      parameters.each.with_index do |(param, types), index|
        value = args[index]

        __typedeaf_validate_types_for(param, value, types)

        # Adding the index of this parameter's value to our Hash so we can
        # properly fish it back out when the method_missing magic is being
        # invoked from within the block
        parameter_indices[param] = value
      end

      return parameter_indices
    end

    # Validate the expected types for a param
    def __typedeaf_validate_types_for(param, value, types)
      validated = false
      if types.is_a? Array
        types.each do |type|
          validated = __typedeaf_valid_type? value, type
          break if validated
        end
      else
        validated = __typedeaf_valid_type? value, types
      end

      unless validated
        raise InvalidTypeException,
            "Expected `#{param}` to be a kind of #{types} but was #{value.class}"
      end
    end

    # If we've been given a block, and it's in the params list properly,
    # then we should just add it to the args as a "positional" argument
    def __typedeaf_handle_nested_block(parameters, args, block)
      if block && parameters[:block]
        args << block
      end
      return nil
    end

    def __typedeaf_handle_default_parameters(parameters, args)
      return unless parameters.keys.size > args.size

      # Check to see if we have any defaulted parameters
      parameters.each do |name, argument|
        # Unless it's a special kind of argument, skip it
        next unless argument.is_a? Typedeaf::Arguments::DefaultArgument

        parameters[name] = argument.types
        args << argument.value
      end

      return nil
    end

    # Validate that we have the right number of positional arguments
    #
    # This is only really needed to make sure we're behaving the same
    # was as natively defined method would
    def __typedeaf_validate_positionals(parameters, args)
      if parameters.keys.size != args.size
        raise ArgumentError,
          "wrong number of arguments (#{args.size} for #{parameters.keys.size})"
      end
      return nil
    end
  end
end
