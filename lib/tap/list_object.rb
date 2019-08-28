# frozen_string_literal: true

module Tap
  class ListObject < TapObject
    include Enumerable
    include Tap::APIOperations::List
    include Tap::APIOperations::Request
    include Tap::APIOperations::Create

    OBJECT_NAME = 'list'.freeze

    attr_accessor :filters

    def self.empty_list(opts = {})
      ListObject.construct_from({ data: [] }, opts)
    end

    def initialize(*args)
      super
      self.filters = {}
    end

    def [](key)
      case key
      when String, Symbol
        super
      else
        raise ArgumentError,
              "You tried to access the #{key.inspect} index, but ListObject " \
              "types only support String keys. (HINT: List calls return an " \
              "object with a 'data' (which is the data array). You likely " \
              "want to call #data[#{key.inspect}])"
      end
    end

    def empty?
      data.empty?
    end

    def each(&blk)
      data.each(&blk)
    end

    def auto_paging_each(&blk)
      return enum_for(:auto_paging_each) unless block_given?

      page = self
      loop do
        page.each(&blk)
        page = page.next_page
        break if page.empty?
      end
    end

    def retrieve(id, opts = {})
      id, retrieve_params = Util.normalize_id(id)
      resp, opts = request(:get, "#{resource_url}/#{CGI.escape(id)}", retrieve_params, opts)
      Util.convert_to_tap_object(resp.data, opts)
    end

    def next_page(params = {}, opts = {})
      return self.class.empty_list(opts) unless has_more

      last_id = data.last.id

      params = filters.merge(starting_after: last_id).merge(params)

      list(params, opts)
    end

    def previous_page(params = {}, opts = {})
      # TODO: Not implemented on the TAP API
    end

    def resource_url
      url || raise(ArgumentError, "List object does not contain a 'url' field.")
    end
  end
end
