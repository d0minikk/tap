# frozen_string_literal: true

module Tap
  class TapError < StandardError
    attr_accessor :response
    attr_reader :message, :code, :http_body, :http_headers, :http_status, :json_body

    def initialize(message = nil, http_status: nil, http_body: nil, json_body: nil, http_headers: nil, code: nil)
      @message = message
      @http_status = http_status
      @http_body = http_body
      @http_headers = http_headers || {}
      @json_body = json_body
      @code = code
    end

    def to_s
      status_string = @http_status.nil? ? '' : "(Status #{@http_status}) "
      "#{status_string}#{@message}"
    end
  end

  class AuthenticationError < TapError
  end

  class APIConnectionError < TapError
  end

  class APIError < TapError
  end

  class InvalidRequestError < TapError
    attr_accessor :param

    def initialize(message, param, http_status: nil, http_body: nil, json_body: nil, http_headers: nil, code: nil)
      super(
        message,
        http_status: http_status,
        http_body: http_body,
        json_body: json_body,
        http_headers: http_headers,
        code: code
      )
      @param = param
    end
  end

  class PermissionError < TapError
  end

  class RateLimitError < TapError
  end

  class SignatureVerificationError < TapError
    attr_accessor :sig_header

    def initialize(message, sig_header, http_body: nil)
      super(message, http_body: http_body)
      @sig_header = sig_header
    end
  end
end
