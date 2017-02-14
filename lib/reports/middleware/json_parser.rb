require 'json'

module Reports
  module Middleware
    class JSONParser < Faraday::Middleware
      def initialize(app, options = {})
        super app
      end

      def call(env)
        @app.call(env).on_complete do |response|
          if json_content? response
            response[:raw_body] = response[:body]
            response[:body] = JSON.parse response[:raw_body]
          end
        end
      end

      private

      def json_content?(response)
        response.response_headers['content-type'] =~ %r{application/json} &&
          response.body.size > 0
      end
    end
  end
end
