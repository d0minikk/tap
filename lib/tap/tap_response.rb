# frozen_string_literal: true

module Tap
  class TapResponse
    attr_accessor :data, :http_body, :http_headers, :http_status

    def self.from_faraday_hash(http_resp)
      resp = TapResponse.new
      resp.data = JSON.parse(http_resp[:body], symbolize_names: true)
      resp.http_body = http_resp[:body]
      resp.http_headers = http_resp[:headers]
      resp.http_status = http_resp[:status]
      resp
    end

    def self.from_faraday_response(http_resp)
      resp = TapResponse.new
      resp.data = JSON.parse(http_resp.body, symbolize_names: true)
      resp.http_body = http_resp.body
      resp.http_headers = http_resp.headers
      resp.http_status = http_resp.status
      resp
    end
  end
end
