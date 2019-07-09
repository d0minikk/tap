# Tap Ruby Library

[Tap Payments API docs](https://tappayments.api-docs.io/2.0)

The Tap Ruby library provides convenient access to the Tap Payments API from
applications written in the Ruby language. It includes a pre-defined set of
classes for API resources that initialize themselves dynamically from API
responses which makes it compatible with a wide range of versions of the Tap
API.

## Documentation

## Installation

You don't need this source code unless you want to modify the gem. If you just
want to use the package, just run:

    gem install tap-ruby

If you want to build the gem from source:

    gem build tap.gemspec

### Requirements

* Ruby 2.0+.

### Bundler

If you are installing via bundler, you should be sure to use the https rubygems
source in your Gemfile, as any gems fetched over http could potentially be
compromised in transit and alter the code of gems fetched securely over https:

``` ruby
source 'https://rubygems.org'

gem 'rails'
gem 'tap-ruby'
```
