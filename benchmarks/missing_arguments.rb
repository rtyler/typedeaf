require_relative 'bench_helper'

class MissingArgs
  include Typedeaf

  def method_with_params(buffer)
    buffer.size + rand + rand
  end

  define :typedeaf_with_params, buffer: String do
    buffer.size + rand + rand
  end
end

blk = lambda do |buffer|
  buffer.size + rand + rand
end

p = MissingArgs.new


Benchmark.ips do |x|
  x.report('typedeaf method') { begin; p.typedeaf_with_params; rescue; end; }
  x.report('normal method') { begin; p.method_with_params; rescue; end; }
  x.report('a simple proc') { begin; blk.(); rescue; end; }
  x.compare!
end
