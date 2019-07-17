# frozen_string_literal: true

module Tap
  class Refund < APIResource
    extend Tap::APIOperations::Create
    extend Tap::APIOperations::PostList
    include Tap::APIOperations::Save

    OBJECT_NAME = 'refund'.freeze
  end
end
