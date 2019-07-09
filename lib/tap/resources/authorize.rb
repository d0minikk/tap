# frozen_string_literal: true

module Tap
  class Authorize < APIResource
    extend Tap::APIOperations::Create
    include Tap::APIOperations::Delete
    include Tap::APIOperations::Save
    extend Tap::APIOperations::PostList

    OBJECT_NAME = 'authorize'.freeze
  end
end
