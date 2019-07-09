# frozen_string_literal: true

module Tap
  class TapClient
    attr_accessor :conn

    def initialize(conn = nil)
      self.conn = conn || self.class.default_conn
    end

    def self.active_client
      Thread.current[:tap_client] || default_client
    end

    def self.default_client
      Thread.current[:tap_client_default_client] ||= TapClient.new(default_conn)
    end

    def self.default_conn
      Thread.current[:tap_client_default_conn] ||= begin
        conn = Faraday.new do |builder|
          builder.use Faraday::Request::Multipart
          builder.use Faraday::Request::UrlEncoded
          builder.use Faraday::Response::RaiseError

          builder.adapter :net_http_persistent
        end

        conn
      end
    end

    def self.should_retry?(e, num_retries)
      return false if num_retries >= Tap.max_network_retries
      return true if e.is_a?(Faraday::TimeoutError)
      return true if e.is_a?(Faraday::ConnectionFailed)
      return true if e.is_a?(Faraday::ClientError) && e.response && e.response[:status] == 409

      false
    end

    def self.sleep_time(num_retries)
      # Apply exponential backoff with initial_network_retry_delay on the
      # number of num_retries so far as inputs. Do not allow the number to exceed
      # max_network_retry_delay.
      sleep_seconds = [Tap.initial_network_retry_delay * (2**(num_retries - 1)), Tap.max_network_retry_delay].min

      # Apply some jitter by randomizing the value in the range of (sleep_seconds
      # / 2) to (sleep_seconds).
      sleep_seconds *= (0.5 * (1 + rand))

      # But never sleep less than the base sleep seconds.
      sleep_seconds = [Tap.initial_network_retry_delay, sleep_seconds].max

      sleep_seconds
    end

    def request
      @last_response = nil
      old_tap_client = Thread.current[:tap_client]
      Thread.current[:tap_client] = self

      begin
        res = yield
        [res, @last_response]
      ensure
        Thread.current[:tap_client] = old_tap_client
      end
    end

    def execute_request(_method, path, api_base: nil, api_key: nil, headers: {}, params: {})
      api_base ||= Tap.api_base
      api_key ||= Tap.api_key

      check_api_key!(api_key)

      params = Util.objects_to_ids(params)
      url = api_url(path, api_base)

      body = nil
      query_params = nil

      case _method.to_s.downcase.to_sym
      when :get, :head, :delete
        query_params = params
      else
        body = params.to_json
      end

      u = URI.parse(path)
      unless u.query.nil?
        query_params ||= {}
        query_params = Hash[URI.decode_www_form(u.query)].merge(query_params)
        path = u.path
      end

      headers = request_headers(api_key, _method).update(Util.normalize_headers(headers))

      context = RequestLogContext.new
      context.api_key         = api_key
      context.body            = body
      context.method          = _method
      context.path            = path
      context.query_params    = query_params ? Util.encode_parameters(query_params) : nil

      http_resp = execute_request_with_rescues(api_base, context) do
        conn.run_request(_method, url, body, headers) do |req|
          req.options.open_timeout = Tap.open_timeout
          req.options.timeout = Tap.read_timeout
          req.params = query_params unless query_params.nil?
        end
      end

      begin
        resp = TapResponse.from_faraday_response(http_resp)
      rescue JSON::ParserError
        raise general_api_error(http_resp.status, http_resp.body)
      end

      @last_response = resp
      [resp, api_key]
    end

    private

    def api_url(url = '', api_base = nil)
      (api_base || Tap.api_base) + url
    end

    def check_api_key!(api_key)
      unless api_key
        raise AuthenticationError, "No API key provided. " \
          'Set your API key using "Tap.api_key = <API-KEY>". ' \
          "You can generate API keys from the Tap web interface. " \
          "See https://tap.com/api for details, or email support@tap.com " \
          "if you have any questions."
      end

      return unless api_key =~ /\s/

      raise AuthenticationError, "Your API key is invalid, as it contains " \
        "whitespace. (HINT: You can double-check your API key from the " \
        "Tap web interface. See https://tap.com/api for details, or " \
        "email support@tap.com if you have any questions.)"
    end

    def execute_request_with_rescues(api_base, context)
      num_retries = 0

      begin
        request_start = Time.now
        log_request(context, num_retries)
        resp = yield
        context = context.dup_from_response(resp)
        log_response(context, request_start, resp.status, resp.body)
      rescue StandardError => e
        error_context = context

        if e.respond_to?(:response) && e.response
          error_context = context.dup_from_response(e.response)
          log_response(error_context, request_start, e.response[:status], e.response[:body])
        else
          log_response_error(error_context, request_start, e)
        end

        if self.class.should_retry?(e, num_retries)
          num_retries += 1
          sleep self.class.sleep_time(num_retries)
          retry
        end

        case e
        when Faraday::ClientError
          if e.response
            handle_error_response(e.response, error_context)
          else
            handle_network_error(e, error_context, num_retries, api_base)
          end
        else
          raise
        end
      end

      resp
    end

    def general_api_error(status, body)
      APIError.new(
        "Invalid response object from API: #{body.inspect} " \
        "(HTTP response code was #{status})",
        http_status: status,
        http_body: body,
      )
    end

    def handle_error_response(http_resp, context)
      begin
        resp = TapResponse.from_faraday_hash(http_resp)
        error_data = resp.data[:error]

        raise TapError, 'Indeterminate error' unless error_data
      rescue JSON::ParserError, TapError
        raise general_api_error(http_resp[:status], http_resp[:body])
      end

      error = specific_api_error(resp, error_data, context)

      error.response = resp
      raise(error)
    end

    def specific_api_error(resp, error_data, context)
      Tap::Log.log_error(
        'Tap API error',
        status: resp.http_status,
        error_code: error_data[:code],
        error_message: error_data[:message],
        error_param: error_data[:param],
        error_type: error_data[:type],
      )

      opts = {
        http_body: resp.http_body,
        http_headers: resp.http_headers,
        http_status: resp.http_status,
        json_body: resp.data,
        code: error_data[:code],
      }

      case resp.http_status
      when 400, 404
        InvalidRequestError.new(error_data[:message], error_data[:param], opts)
      when 401
        AuthenticationError.new(error_data[:message], opts)
      when 403
        PermissionError.new(error_data[:message], opts)
      when 429
        RateLimitError.new(error_data[:message], opts)
      else
        APIError.new(error_data[:message], opts)
      end
    end

    def handle_network_error(e, context, num_retries, api_base = nil)
      Tap::Log.log_error('Tap network error', error_message: e.message)

      case e
      when Faraday::ConnectionFailed
        message = "Unexpected error communicating when trying to connect to Tap. " \
          "You may be seeing this message because your DNS is not working. " \
          "To check, try running 'host tap.com' from the command line."
      when Faraday::SSLError
        message = "Could not establish a secure connection to Tap, you may " \
                  "need to upgrade your OpenSSL version. To check, try running " \
                  "'openssl s_client -connect api.tap.com:443' from the " \
                  "command line."
      when Faraday::TimeoutError
        api_base ||= Tap.api_base
        message = "Could not connect to Tap (#{api_base}). " \
          "Please check your internet connection and try again. " \
          "If this problem persists, you should check Tap's service status"
      else
        message = "Unexpected error communicating with Tap. " \
          "If this problem persists, let us know at support@Tap.com."

      end

      message += " Request was retried #{num_retries} times." if num_retries > 0

      raise APIConnectionError, message + "\n\n(Network error: #{e.message})"
    end

    def request_headers(api_key, _method)
      {
        'Authorization' => "Bearer #{api_key}",
        'Content-Type' => 'application/json',
      }
    end

    def log_request(context, num_retries)
      Tap::Log.log_info(
        'Request to Tap API',
        method: context.method,
        num_retries: num_retries,
        path: context.path
      )

      Tap::Log.log_debug('Request details', body: context.body, query_params: context.query_params)
    end
    private :log_request

    def log_response(context, request_start, status, body)
      Tap::Log.log_info(
        'Response from Tap API',
        elapsed: Time.now - request_start,
        method: context.method,
        path: context.path,
        status: status
      )
      Tap::Log.log_debug('Response details', body: body)
    end
    private :log_response

    def log_response_error(context, request_start, e)
      Tap::Log.log_error('Request error',
                     elapsed: Time.now - request_start,
                     error_message: e.message,
                     method: context.method,
                     path: context.path)
    end
    private :log_response_error

    class RequestLogContext
      attr_accessor :body, :api_key, :method, :path, :query_params

      def dup_from_response(resp)
        return self if resp.nil?

        headers = resp.is_a?(Faraday::Response) ? resp.headers : resp[:headers]
        context = dup
        context
      end
    end
  end
end
