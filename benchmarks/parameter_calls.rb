require_relative 'bench_helper'

class Parametered
  include Typedeaf

  def method_with_params(buffer)
    buffer.size
  end

  define :typedeaf_with_params, buffer: String do
    buffer.size
  end
end

blk = Proc.new do |buffer|
  buffer.size
end

p = Parametered.new

Benchmark.ips do |x|
  x.report('typedeaf method') { |i| p.typedeaf_with_params(i.to_s) }
  x.report('normal method') { |i| p.method_with_params(i.to_s) }
  x.report('a simple proc') { |i| blk.(i.to_s) }
  x.compare!
end
