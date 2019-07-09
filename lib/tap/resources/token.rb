# frozen_string_literal: true

module Tap
  class Token < APIResource
    # extend Tap::APIOperations::Create
    # To use this API, you need to provide PCI compliance certificate.
    # You can create the token, by using our  without PCI compliance.

    OBJECT_NAME = 'token'.freeze
  end
end
