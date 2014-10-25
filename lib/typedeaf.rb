require 'typedeaf/errors'
require "typedeaf/version"

module Typedeaf
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.extend(ClassMethods)
  end

  module InstanceMethods
    def __typedeaf_varstack__
      if @__typedeaf_varstack__.nil?
        @__typedeaf_varstack__ = []
      end
      return @__typedeaf_varstack__
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

  module ClassMethods
    def define(method_sym, params={}, &block)
      if block.nil?
        raise MissingMethodException,
            "You must provide a block for the #{method_sym} body"
      end

      define_method(method_sym) do |*args|
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
