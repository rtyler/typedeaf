# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'typedeaf/version'

Gem::Specification.new do |spec|
  spec.name          = "typedeaf"
  spec.version       = Typedeaf::VERSION
  spec.authors       = ["R. Tyler Croy"]
  spec.email         = ["tyler@monkeypox.org"]
  spec.summary       = %q{Typedeaf is a gem to help add some type-checking to method declarations in Ruby}
  spec.homepage      = "https://github.com/rtyler/typedeaf"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
end
