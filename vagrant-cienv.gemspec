# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-qienv/version'

Gem::Specification.new do |spec|
  spec.name          = "vagrant-qienv"
  spec.version       = VagrantPlugins::Cienv::VERSION
  spec.authors       = ["Alfredo Matas"]
  spec.email         = ["amatas@gmail.com"]

  spec.summary       = %q{Vagrant CI environment builder}
  spec.description   = %q{Vagrant CI environment builder}
  spec.homepage      = "http://github.com/amatas/vagrant-qienv.git"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files`.split($\)
  spec.executables   = spec.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "method_source", "~> 0.8.2"
end
