# frozen_string_literal: true

module Tap
  module APIOperations
    module PostList
      def list(filters = {}, opts = {})
        opts = Util.normalize_opts(opts)

        resp, opts = request(:post, resource_url + '/list', filters, opts)
        obj = Tap::ListObject.construct_from(resp.data, opts)
        obj.filters = filters.dup
        obj.filters.delete(:starting_after)

        obj
      end

      alias all list
    end
  end
end
