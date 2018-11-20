# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

group :development do
  gem 'coveralls', require: false
  gem 'mocha', '~> 0.13.2'
  gem 'rake'
  gem 'shoulda-context'
  gem 'test-unit'
  gem 'timecop'
  gem 'webmock'

  gem 'rubocop', '0.50.0'

  # Rack 2.0+ requires Ruby >= 2.2.2 which is problematic for the test suite on
  # older Ruby versions. Check Ruby the version here and put a maximum
  # constraint on Rack if necessary.
  if RUBY_VERSION >= '2.2.2'
    gem 'rack', '>= 2.0.6'
  else
    gem 'rack', '>= 1.6.11', '< 2.0' # rubocop:disable Bundler/DuplicatedGem
  end

  platforms :mri do
    gem 'byebug'
    gem 'pry'
    gem 'pry-byebug'
  end
end
