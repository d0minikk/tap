# frozen_string_literal: true

module Tap
  module Webhook
    def self.construct_resource(payload, sig_header, secret)
      Signature.verify_header(payload, sig_header, secret)

      data = JSON.parse(payload, symbolize_names: true)
      Tap::TapObject.initialize_from(data, opts)
    end

    module Signature
      def self.verify_header(payload, signature_header, secret)
        if signature_header.empty?
          raise SignatureVerificationError.new('No signatures found', signature_header, http_body: payload)
        end

        payload_string = Signature.retrive_payload_string(payload)
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

      def self.retrive_payload_string(payload)
        attributes = payload[:charge] || payload[:authorize]

        [:id, :amount, :currency, :gateway_reference, :payment_reference, :status, :created].map do |attribute|
          "x_#{attributes[attribute]}"
        end.join('')
      end
      private_class_method :retrive_payload_string
    end
  end
end
