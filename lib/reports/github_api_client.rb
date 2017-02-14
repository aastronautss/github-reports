require 'faraday'
require 'json'
require 'logger'
require_relative 'middleware/logging'
require_relative 'middleware/authentication'

module Reports

  class Error < StandardError; end
  class NonexistentUser < Error; end
  class RequestFailure < Error; end
  class AuthenticationFailure < Error; end

  VALID_STATUS_CODES = [200, 302, 401, 403, 404, 422]
  User = Struct.new :name, :location, :public_repos
  Repository = Struct.new :full_name, :svn_url

  class GitHubAPIClient
    def get_user(username)
      response = get "https://api.github.com/users/#{username}"

      if !VALID_STATUS_CODES.include? response.status
        request RequestFailure, JSON.parse(response.body)['message']
      end

      if response.status == 404
        raise NonexistentUser, "'#{username}' does not exist"
      end

      data = JSON.parse response.body
      User.new data['name'], data['location'], data['public_repos']
    end

    def public_repos_for_user(username)
      response = get "https://api.github.com/users/#{username}/repos"


      if !VALID_STATUS_CODES.include? response.status
        request RequestFailure, JSON.parse(response.body)['message']
      end

      if response.status == 404
        raise NonexistentUser, "'#{username}' does not exist"
      end

      data = JSON.parse response.body
      data.map do |repo_data|
        Repository.new repo_data['full_name'], repo_data['svn_url']
      end
    end

    private

    def connection
      @connection ||= Faraday::Connection.new do |c|
        c.use Middleware::Authentication
        c.use Middleware::Logging

        c.adapter Faraday.default_adapter
      end
    end

    def get(url)
      connection.get url, nil, headers
    end
  end

end
