# frozen_string_literal: true

require 'cgi'
require 'faraday'
require 'json'
require 'logger'
require 'openssl'
require 'securerandom'
require 'set'
require 'socket'
require 'uri'

require 'tap/version'

require 'tap/api_operations/create'
require 'tap/api_operations/delete'
require 'tap/api_operations/list'
require 'tap/api_operations/post_list'
require 'tap/api_operations/request'
require 'tap/api_operations/save'

require 'tap/errors'
require 'tap/log'
require 'tap/object_types'
require 'tap/util'
require 'tap/tap_client'
require 'tap/tap_object'
require 'tap/tap_response'
require 'tap/list_object'
require 'tap/api_resource'

require 'tap/resources'

module Tap
  @api_base = 'https://api.tap.company'

  @log_level = nil
  @logger = nil

  @max_network_retries = 0
  @max_network_retry_delay = 2
  @initial_network_retry_delay = 0.5

  @open_timeout = 30
  @read_timeout = 80

  class << self
    attr_accessor :api_key, :api_base, :open_timeout, :read_timeout
    attr_reader :max_network_retry_delay, :initial_network_retry_delay
  end

  LEVEL_DEBUG = Logger::DEBUG
  LEVEL_ERROR = Logger::ERROR
  LEVEL_INFO = Logger::INFO

  def self.log_level
    @log_level
  end

  def self.log_level=(val)
    if !val.nil? && ![LEVEL_DEBUG, LEVEL_ERROR, LEVEL_INFO].include?(val)
      raise ArgumentError, "log_level should only be set to `nil`, `debug` or `info`"
    end
    @log_level = val
  end

  def self.logger
    @logger
  end

  def self.logger=(val)
    @logger = val
  end

  def self.max_network_retries
    @max_network_retries
  end

  def self.max_network_retries=(val)
    @max_network_retries = val.to_i
  end
end

Tap.log_level = ENV['TAP_LOG'] unless ENV['TAP_LOG'].nil?
