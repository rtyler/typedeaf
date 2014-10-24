# Typedeaf

Typedeaf is a gem to help add some type-checking to method declarations in Ruby


## Usage

```
[1] pry(main)> require 'typedeaf'
=> true
[2] pry(main)> class Logger
[2] pry(main)*   include Typedeaf
[2] pry(main)*   
[2] pry(main)*   define :log, message: String, level: Symbol do
[2] pry(main)*     puts "Logging #{message} at level #{level}"
[2] pry(main)*   end  
[2] pry(main)* end  
=> Logger
[3] pry(main)> l = Logger.new
=> #<Logger:0x00000803c616b8>
[4] pry(main)> l.log("Hello World", :debug)
Logging Hello World at level debug
=> nil
[5] pry(main)> l.log(4, :debug)
Typedeaf::InvalidTypeException: Expected `message` to be a kind of String but was Fixnum
from /usr/home/tyler/source/github/ruby/typedeaf/lib/typedeaf.rb:41:in `type_validation!'
[6] pry(main)> l.log('Whoopsies', 'debug')
Typedeaf::InvalidTypeException: Expected `level` to be a kind of Symbol but was String
from /usr/home/tyler/source/github/ruby/typedeaf/lib/typedeaf.rb:41:in `type_validation!'
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

