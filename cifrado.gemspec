# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cifrado/version'

Gem::Specification.new do |gem|
  gem.name          = "cifrado"
  gem.version       = Cifrado::VERSION
  gem.authors       = ["Sergio Rubio"]
  gem.email         = ["rubiojr@frameos.org"]
  gem.description   = %q{Encrypted OpenStack Swift uploads}
  gem.summary       = %q{Encrypted OpenStack Swift uploads}
  gem.homepage      = "https://github.com/rubiojr/cifrado"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_dependency 'excon'
  gem.add_dependency 'thor', '>= 0.17'
  gem.add_dependency 'progressbar'
  
  gem.add_development_dependency 'shindo'
end
