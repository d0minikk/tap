# frozen_string_literal: true

module Tap
  module Webhook
    def self.construct_resource(payload, sig_header, secret)
      data = JSON.parse(payload, symbolize_names: true)
      resource = Tap::Util.convert_to_tap_object(data)

      Signature.verify_header(payload, resource, sig_header, secret)
    end

    module Signature
      def self.verify_header(payload, resource, signature_header, secret)
        if signature_header.empty?
          raise SignatureVerificationError.new('No signatures found', signature_header, http_body: payload)
        end

        payload_string = Signature.retrive_hashstring(resource)
        expected_sig = compute_signature(payload_string, secret)

        unless Util.secure_compare(expected_sig, s)
          raise SignatureVerificationError.new(
            'No signatures found matching the expected signature for payload',
            header,
            http_body: payload
          )
        end

        true
      end

      def self.compute_signature(payload, secret)
        OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), payload, secret)
      end
      private_class_method :compute_signature

      def self.retrive_hashstring(resource)
        hashstring = {
          id: resource.id,
          amount: resource.amount,
          currency: resource.currency,
          gateway_reference: resource.reference.gateway,
          payment_reference: resource.reference.payment,
          status: resource.status,
          created: resource.transaction.created,
        }

        hashstring.map do |k, v|
          "x_#{k}#{v}"
        end.join('')
      end

      private_class_method :retrive_hashstring
    end
  end
end
