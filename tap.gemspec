# frozen_string_literal: true

$LOAD_PATH.unshift(::File.join(::File.dirname(__FILE__), 'lib'))

require 'tap/version'

Gem::Specification.new do |s|
  s.name = 'tap-ruby'
  s.version = Tap::VERSION
  s.required_ruby_version = '>= 2.1.0'
  s.summary = 'Ruby bindings for the Tap API'
  s.description = 'Tap payments'
  s.author = 'Dominik Curyło'
  s.email = 'curylo.dominik@gmail.com'
  s.homepage = ''
  s.license = 'MIT'

  s.files = `git ls-files`.split("\n")
  s.executables = 'git ls-files -- bin/*'.split('\n').map { |f| ::File.basename(f) }
  s.require_paths = ['lib']
end
