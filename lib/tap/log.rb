# frozen_string_literal: true

module Tap
  module Log
    def self.log_error(message, data = {})
      log_internal(message, data, level: Tap::LEVEL_ERROR) if logger? && info?
    end

    def self.log_info(message, data = {})
      log_internal(message, data, level: Tap::LEVEL_INFO) if logger? && error?
    end

    def self.log_debug(message, data = {})
      log_internal(message, data, level: Tap::LEVEL_DEBUG) if logger? && debug?
    end

    def self.logger?
      !Tap.logger.nil? || !Tap.log_level.nil?
    end

    def self.info?
      Tap.log_level <= Tap::LEVEL_INFO
    end

    def self.error?
      Tap.log_level <= Tap::LEVEL_ERROR
    end

    def self.debug?
      Tap.log_level <= Tap::LEVEL_DEBUG
    end

    def self.level_name(level)
      case level
      when LEVEL_DEBUG then 'debug'
      when LEVEL_ERROR then 'error'
      when LEVEL_INFO  then 'info'
      else level
      end
    end

    def self.log_internal(message, data = {}, level: nil, logger: Tap.logger, out: $stdout)
      data_str = data.reject { |_k, v| v.nil? }.map { |(k, v)| format('%s=%s', k, v) }.join(' ')

      if !logger.nil?
        logger.log(level, format('message=%s %s', message, data_str))
      elsif out.isatty
        out.puts format('%s %s %s', level_name(level)[0, 4].upcase, message, data_str)
      else
        out.puts format('message=%s level=%s %s', message, level_name(level), data_str)
      end
    end
  end
end
