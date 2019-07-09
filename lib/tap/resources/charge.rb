# frozen_string_literal: true

module Tap
  class Charge < APIResource
    extend Tap::APIOperations::PostList
    extend Tap::APIOperations::Create
    include Tap::APIOperations::Save

    OBJECT_NAME = 'charge'.freeze
  end
end
