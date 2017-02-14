module Reports
  module Middleware
    class Authentication < Faraday::Middleware
      def initialize(app, options = {})
        super app
        @token = ENV['GITHUB_TOKEN']
      end

      def call(env)
        env.request_headers['Authorization'] = "token #{@token}"

        @app.call(env).on_complete do |response|
          if response.status == 401
            raise AuthenticationFailure, 'Authentication Failed. Please set the "GITHUB_TOKEN" environment variable to a valid token.'
          end
        end
      end
    end
  end
end
