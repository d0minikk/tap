# frozen_string_literal: true

module Tap
  class Customer < APIResource
    extend Tap::APIOperations::Create
    include Tap::APIOperations::Delete
    include Tap::APIOperations::Save
    extend Tap::APIOperations::PostList

    OBJECT_NAME = 'customer'.freeze

    def charges(params = {}, opts = {})
      opts = @opts.merge(Util.normalize_opts(opts))
      Charge.all(params.merge(customers: [id]), opts)
    end
  end
end
