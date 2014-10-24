require 'typedeaf/errors'
require "typedeaf/version"

require 'continuation'
require 'facets/binding'

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
  end

  module ClassMethods
    def define(method_sym, params={}, &block)
      if block.nil?
        raise MissingMethodException,
            "You must provide a block for the #{method_sym} body"
      end

      define_method(method_sym) do |*args|
        param_indices = {}
        params.each.with_index do |(key, value), index|
          param_indices[key] = args[index]
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
