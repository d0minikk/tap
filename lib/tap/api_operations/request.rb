# frozen_string_literal: true

module Tap
  module APIOperations
    module Request
      module ClassMethods
        def request(method, url, params = {}, opts = {})
          opts = Util.normalize_opts(opts)
          opts[:client] ||= TapClient.active_client

          headers = opts.clone
          api_key = headers.delete(:api_key)
          api_base = headers.delete(:api_base)
          client = headers.delete(:client)

          resp, opts[:api_key] = client.execute_request(
            method,
            url,
            api_base: api_base,
            api_key: api_key,
            headers: headers,
            params: params
          )

          [
            resp,
            opts.except { |k, v| !Util::OPTS_PERSISTABLE.include?(k) }
          ]
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      protected

      def request(method, url, params = {}, opts = {})
        opts = @opts.merge(Util.normalize_opts(opts))
        self.class.request(method, url, params, opts)
      end
    end
  end
end
