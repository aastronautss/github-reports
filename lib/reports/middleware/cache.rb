require 'time'

module Reports
  module Middleware
    class Cache < Faraday::Middleware
      def initialize(app, options = {})
        super app
        @storage = {}
      end

      def call(env)
        key = env.url.to_s
        cached_response = @storage[key]

        if cached_response && !needs_revalidation?(cached_response)
          return cached_response
        end

        response = @app.call(env)

        response.on_complete do
          @storage[key] = response if cacheable?(env)
        end

        response
      end

      private

      def cacheable?(env)
        cache_control = env[:response_headers]['Cache-Control']

        cache_control && !(cache_control =~ %r{no-store}) && env.method == :get
      end

      def needs_revalidation?(cached_response)
        cache_control = cached_response.headers['Cache-Control']
        stale_cache?(cached_response) ||
          cache_control =~ %r{no-cache} ||
          cache_control =~ %r{must-revalidate}
      end

      def stale_cache?(cached_response)
        age = response_age cached_response
        max_age = response_max_age cached_response

        (age && max_age) ? age > max_age : true
      end

      def response_age(cached_response)
        date = cached_response.headers['Date']
        time = Time.httpdate(date) if date
        (Time.now - time).floor if time
      end

      def response_max_age(cached_response)
        cache_control = cached_response.headers['Cache-Control']
        return nil unless cache_control
        match = cache_control.match /max\-age=(\d+)/
        match[1].to_i if match
      end
    end
  end
end
