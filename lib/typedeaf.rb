require 'thread'

require 'typedeaf/errors'
require "typedeaf/version"

module Typedeaf
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.extend(ClassMethods)
  end

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

  class DefaultArgument
    attr_reader :value, :types
    def initialize(value, *types)
      @value = value
      @types = types
    end
  end

  module ClassMethods
    def default(value, *types)
      return DefaultArgument.new(value, *types)
    end

    def define(method_sym, params={}, &block)
      if block.nil?
        raise MissingMethodException,
            "You must provide a block for the #{method_sym} body"
      end

      define_method(method_sym) do |*args|
        if params.keys.size > args.size
          # Check to see if we have any defaulted parameters
          params.each do |name, argument|
            # Unless it's a special kind of argument, skip it
            next unless argument.is_a? DefaultArgument

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
          instance_exec(*args, &block)
        ensure
          __typedeaf_varstack__.pop
        end
      end
      return self
    end
  end

  # Install the Typedeaf methods onto Class to be used everywhere
  def self.global_install
    Class.class_eval do
      include Typedeaf

      alias_method :old_inherited, :inherited
      def inherited(subclass)
        subclass.class_eval do
          include Typedeaf
        end
        return old_inherited(subclass)
      end
    end
  end
end
