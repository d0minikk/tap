# frozen_string_literal: true

module Tap
  class Card < APIResource
    include Tap::APIOperations::Save
    include Tap::APIOperations::Delete
    extend Tap::APIOperations::List

    OBJECT_NAME = 'card'.freeze
  end
end
