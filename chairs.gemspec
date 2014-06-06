# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chair/version'

Gem::Specification.new do |spec|
  spec.name          = 'chair'
  spec.version       = Chair::VERSION
  spec.date          = '2014-06-04'
  spec.summary       = "Tables!"
  spec.description   = "A pure ruby table implementation with arbitray column indices"
  spec.authors       = ["Katherine Whitlock"]
  spec.email         = 'toroidalcode@gmail.com'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.homepage      = 'http://github.com/toroidal-code/chair'
  spec.license       = 'MIT'

  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
end
