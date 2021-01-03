# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ts_routes/version"

Gem::Specification.new do
  # @type [Gem::Specification] spec
  |spec|

  spec.name          = "ts_routes"
  spec.version       = TsRoutes::VERSION
  spec.authors       = ["FUJI Goro (gfx)"]
  spec.email         = ["goro-fuji@bitjourney.com"]

  spec.summary       = %q{Rails routing helpers for TypeScript}
  spec.description   = %q{Rails routing helpers for TypeScript, inspired by js-routes (https://github.com/railsware/js-routes)}
  spec.homepage      = "https://github.com/bitjourney/ts_routes-rails"
  spec.license       = "Apache-2.0"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test/|spec/|features/|package-lock\.json)})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.5.0"

  spec.add_runtime_dependency "railties", ">= 4.0"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest", "~> 5.0"
end
