# frozen_string_literal: true

require 'cgi'

module Tap
  module Util
    OPTS_USER_SPECIFIED = Set[:api_key, :tap_version].freeze
    OPTS_COPYABLE = (OPTS_USER_SPECIFIED + Set[:api_base]).freeze
    OPTS_PERSISTABLE = (OPTS_USER_SPECIFIED + Set[:client]).freeze

    def self.objects_to_ids(h)
      case h
      when APIResource
        h.id
      when Hash
        res = {}
        h.each { |k, v| res[k] = objects_to_ids(v) unless v.nil? }
        res
      when Array
        h.map { |v| objects_to_ids(v) }
      else
        h
      end
    end

    def self.object_classes
      @object_classes ||= Tap::ObjectTypes.object_names_to_classes
    end

    def self.convert_to_tap_object(data, opts = {})
      case data
      when Array
        data.map { |i| convert_to_tap_object(i, opts) }
      when Hash
        object_classes.fetch(data[:object], TapObject).construct_from(data, opts)
      else
        data
      end
    end

    def self.symbolize_names(object)
      case object
      when Hash
        new_hash = {}
        object.each do |key, value|
          key = (begin
                   key.to_sym
                 rescue StandardError
                   key
                 end) || key
          new_hash[key] = symbolize_names(value)
        end
        new_hash
      when Array
        object.map { |value| symbolize_names(value) }
      else
        object
      end
    end

    def self.encode_parameters(params)
      Util.flatten_params(params).map { |k, v| "#{url_encode(k)}=#{url_encode(v)}" }.join("&")
    end

    def self.url_encode(key)
      CGI.escape(key.to_s).gsub("%5B", "[").gsub("%5D", "]")
    end

    def self.flatten_params(params, parent_key = nil)
      result = []

      # do not sort the final output because arrays (and arrays of hashes
      # especially) can be order sensitive, but do sort incoming parameters
      params.each do |key, value|
        calculated_key = parent_key ? "#{parent_key}[#{key}]" : key.to_s
        if value.is_a?(Hash)
          result += flatten_params(value, calculated_key)
        elsif value.is_a?(Array)
          result += flatten_params_array(value, calculated_key)
        else
          result << [calculated_key, value]
        end
      end

      result
    end

    def self.flatten_params_array(value, calculated_key)
      result = []
      value.each_with_index do |elem, i|
        if elem.is_a?(Hash)
          result += flatten_params(elem, "#{calculated_key}[#{i}]")
        elsif elem.is_a?(Array)
          result += flatten_params_array(elem, calculated_key)
        else
          result << ["#{calculated_key}[#{i}]", elem]
        end
      end
      result
    end

    def self.normalize_id(id)
      if id.is_a?(Hash)
        params_hash = id.dup
        id = params_hash.delete(:id)
      else
        params_hash = {}
      end
      [id, params_hash]
    end

    def self.normalize_opts(opts)
      case opts
      when String
        { api_key: opts }
      when Hash
        check_api_key!(opts.fetch(:api_key)) if opts.key?(:api_key)
        opts.clone
      else
        raise TypeError, 'normalize_opts expects a string or a hash'
      end
    end

    def self.check_string_argument!(key)
      raise TypeError, 'argument must be a string' unless key.is_a?(String)
      key
    end

    def self.check_api_key!(key)
      raise TypeError, 'api_key must be a string' unless key.is_a?(String)
      key
    end

    def self.normalize_headers(headers)
      headers.each_with_object({}) do |(k, v), new_headers|
        k = k.to_s.tr('_', '-') if k.is_a?(Symbol)
        k = k.split('-').reject(&:empty?).map(&:capitalize).join('-')

        new_headers[k] = v
      end
    end
  end
end
