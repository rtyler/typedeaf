require 'thread'
require 'typedeaf/errors'

  module Typedeaf
    module InstanceMethods
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

    def positional_validation!(params, args)
      if params.size != args.size
        raise ArgumentError,
          "wrong number of arguments (#{args.size} for #{params.size})"
      end
    end

    # Determine whether the supplied value is an instance of the given class
    #
    # @param [Object] value
    # @param [Class] type Any class
    def __typedeaf_valid_type?(value, type)
      return value.is_a? type
    end

    # Validated the expect
    def type_validation!(param, value, types)
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
  end
end
