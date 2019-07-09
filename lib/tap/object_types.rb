# frozen_string_literal: true

module Tap
  module ObjectTypes
    def self.object_names_to_classes
      {
        ListObject::OBJECT_NAME => ListObject,
        Authorize::OBJECT_NAME => Authorize,
        Card::OBJECT_NAME => Card,
        Charge::OBJECT_NAME => Charge,
        Customer::OBJECT_NAME => Customer,
        Refund::OBJECT_NAME => Refund,
        Token::OBJECT_NAME => Token,
      }
    end
  end
end
