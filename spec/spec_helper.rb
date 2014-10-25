require 'rubygems'
require 'typedeaf'

require 'rspec'
require 'rspec/its'

unless RUBY_PLATFORM == 'java'
  require 'debugger/pry'
end
