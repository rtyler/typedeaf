require 'thread'

require 'typedeaf/arguments'
require 'typedeaf/errors'

  module Typedeaf
    module InstanceMethods
    def method_missing(varname, *args)
      # We only want to peek at the stack if we have no args (i.e. not trying
      # to make a method call
      if args.empty?
        element = __typedeaf_varstack__.last

        # If our stack is empty then we'll get a nil element back, making sure
        # we only call into __typedeaf_varstack__ once for the #method_missing
        # invocation
        unless element.nil?
          method_name = element.first
          # The top of our stack contains something that we want
          if self.class.__typedeaf_method_parameters__[method_name][varname]
            return element.last[varname]
          end
        end
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
      if @__typedeaf_varstack_id__.nil?
        @__typedeaf_varstack_id__ = "typedeaf_varstack_#{self.object_id}".to_sym
      end

      if Thread.current[@__typedeaf_varstack_id__].nil?
        Thread.current[@__typedeaf_varstack_id__] = []
      end
      return Thread.current[@__typedeaf_varstack_id__]
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
      index = 0
      parameters.each do |param, types|
        value = args[index]
        index = index + 1

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

      # If we've received a DefaultArgument, we need to dig into it to get our
      # types to check back out
      if types.is_a? Typedeaf::Arguments::DefaultArgument
        types = types.types
      end

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
      # If both parameters and args are of equal size, then we don't have any
      # defaulted parameters that we need to insert
      return unless parameters.size > args.size

      # Check to see if we have any defaulted parameters
      parameters.each do |name, argument|
        # Unless it's a special kind of argument, skip it
        next unless argument.is_a? Typedeaf::Arguments::DefaultArgument

        args << argument.value
      end

      return nil
    end

    # Validate that we have the right number of positional arguments
    #
    # This is only really needed to make sure we're behaving the same
    # was as natively defined method would
    def __typedeaf_validate_positionals(parameters, args)
      if parameters.size != args.size
        raise ArgumentError,
          "wrong number of arguments (#{args.size} for #{parameters.size})"
      end
      return nil
    end
  end
end
