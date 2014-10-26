require 'rubygems'

$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/../lib'))
require 'typedeaf'
require 'benchmark/ips'

class Simple
  include Typedeaf
  def method_computer
    rand + rand
  end

  define :typedeaf_computer do
    rand + rand
  end
end

s = Simple.new

b = Proc.new do
  rand + rand
end

Benchmark.ips do |x|
  x.report('typedeaf method') { s.typedeaf_computer }
  x.report('normal method') { s.method_computer }
  x.report('a simple proc') { b.() }
  x.compare!
end
