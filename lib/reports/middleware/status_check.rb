module Reports
  module Middleware
    class StatusCheck < Faraday::Middleware
      VALID_STATUS_CODES = [200, 302, 401, 403, 404, 422]

      def initialize(app, options = {})
        super app
      end

      def call(env)
        @app.call(env).on_complete do |response|
          if !VALID_STATUS_CODES.include? response.status
            request RequestFailure, JSON.parse(response.body)['message']
          end
        end
      end
    end
  end
end
