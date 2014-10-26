require 'rubygems'
require 'typedeaf'

require 'rspec'
require 'rspec/its'

unless RUBY_PLATFORM == 'java'
  begin
    require 'debugger/pry'
  rescue LoadError
    puts 'Not loading debugger/pry'
  end
end
