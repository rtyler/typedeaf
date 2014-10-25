# Typedeaf

Typedeaf is a gem to help add some type-checking to method declarations in Ruby


## Usage

### Writing your Typedeaf'd code

```ruby
require 'typedeaf'

class Logger
  include Typedeaf

  # Log an error
  #
  # @param [String] messaage
  define :error, message: String do
    # Just delegate to the #log method nad pass
    # the level of error
    self.log(message, :error)
  end

  # Log a simple message to STDOUT
  #
  # @param [String] message The log message to log 
  # @param [Symbol] level The level at which to log the
  #     message, defaults to :info
  define :log, message: String, level: default(:info, Symbol) do
    puts "[#{level}] #{message}"
  end
end
```

### Calling Typedeaf'd code

```
[1] pry(main)> require './logger'
=> true
[2] pry(main)> l = Logger.new
=> #<Logger:0x00000803c616b8>
[3] pry(main)> l.log 'test 1, 2, 3'
[info] test 1, 2, 3
=> nil
[4] pry(main)> l.log 'this is SUPER SERIOUS', :critical
[critical] this is SUPER SERIOUS
=> nil
[5] pry(main)> l.error(5) # wrong type!
Typedeaf::InvalidTypeException: Expected `message` to be a kind of String but was Fixnum
from /usr/home/tyler/source/github/ruby/typedeaf/lib/typedeaf.rb:58:in `type_validation!'
[6] pry(main)> l.log("This doesn't use the right type either", 1)
Typedeaf::InvalidTypeException: Expected `level` to be a kind of [Symbol] but was Fixnum
from /usr/home/tyler/source/github/ruby/typedeaf/lib/typedeaf.rb:58:in `type_validation!'
[7] pry(main)> 

```


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'typedeaf'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install typedeaf

