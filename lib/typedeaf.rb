require 'typedeaf/classmethods'
require 'typedeaf/instancemethods'
require "typedeaf/version"

module Typedeaf
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.extend(ClassMethods)
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
