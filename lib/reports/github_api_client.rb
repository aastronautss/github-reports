require 'faraday'
require 'json'
require 'logger'

module Reports

  class Error < StandardError; end
  class NonexistentUser < Error; end
  class RequestFailure < Error; end
  class AuthenticationFailure < Error; end

  VALID_STATUS_CODES = [200, 302, 401, 403, 404, 422]
  User = Struct.new :name, :location, :public_repos

  class GitHubAPIClient
    def initialize(access_token)
      @logger = Logger.new STDOUT
      @logger.formatter = proc do |severity, datetime, program, message|
        message + "\n"
      end

      @access_token = access_token
    end

    def get_user(username)
      response = get "https://api.github.com/users/#{username}"

      if !VALID_STATUS_CODES.include? response.status
        request RequestFailure, JSON.parse(response.body)['message']
      end

      if response.status == 401
        raise AuthenticationFailure, 'Authentication Failed. Please set the "GITHUB_TOKEN" environment variable to a valid token.'
      end

      if response.status == 404
        raise NonexistentUser, "'#{username}' does not exist"
      end

      data = JSON.parse response.body
      User.new data['name'], data['location'], data['public_repos']
    end

    private

    def client
      @client ||= Faraday.new
    end

    def get(url)
      headers = { 'Authorization' => "token #{@access_token}" }

      start_time = Time.now
      response = client.get url, nil, headers
      duration = Time.now - start_time

      @logger.debug '-> %s %s %d (%.3f s)' % [url, 'GET', response.status, duration]

      response
    end
  end

end
