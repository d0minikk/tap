# frozen_string_literal: true

$LOAD_PATH.unshift(::File.join(::File.dirname(__FILE__), 'lib'))

require 'tap/version'

Gem::Specification.new do |s|
  s.name = 'tap'
  s.version = Tap::VERSION
  s.required_ruby_version = '>= 2.1.0'
  s.summary = 'Ruby bindings for the Tap API'
  s.description = 'Tap payments'
  s.author = 'Dominik Curyło'
  s.email = ''
  s.homepage = ''
  s.license = 'MIT'

  s.files = `git ls-files`.split("\n")
  s.require_paths = ['lib']
end
