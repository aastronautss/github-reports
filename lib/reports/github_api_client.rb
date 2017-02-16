require 'faraday'
require 'json'
require 'logger'

require_relative 'middleware/logging'
require_relative 'middleware/authentication'
require_relative 'middleware/status_check'
require_relative 'middleware/json_parser'
require_relative 'middleware/cache'

require_relative 'storage/redis'

module Reports

  class Error < StandardError; end
  class NonexistentUser < Error; end
  class RequestFailure < Error; end
  class AuthenticationFailure < Error; end
  class ConfigurationError < Error; end

  User = Struct.new :name, :location, :public_repos
  Repository = Struct.new :full_name, :svn_url
  Event = Struct.new :type, :repo_name

  class GitHubAPIClient
    def get_user(username)
      response = get "https://api.github.com/users/#{username}"

      if response.status == 404
        raise NonexistentUser, "'#{username}' does not exist"
      end

      data = response.body
      User.new data['name'], data['location'], data['public_repos']
    end

    def public_repos_for_user(username)
      response = get "https://api.github.com/users/#{username}/repos"

      if response.status == 404
        raise NonexistentUser, "'#{username}' does not exist"
      end

      response.body.map do |repo_data|
        Repository.new repo_data['full_name'], repo_data['svn_url']
      end
    end

    def public_activity_for_user(username)
      data = get_pages "https://api.github.com/users/#{username}/events/public"

      data.map do |event_data|
        Event.new event_data['type'], event_data['repo']['name']
      end
    end

    private

    def connection
      @connection ||= Faraday::Connection.new do |c|
        c.use Middleware::Authentication
        c.use Middleware::StatusCheck
        c.use Middleware::Cache, Storage::Redis.new
        c.use Middleware::Logging
        c.use Middleware::JSONParser

        c.adapter Faraday.default_adapter
      end
    end

    def get(url)
      connection.get url
    end

    def get_pages(url, collection = [])
      res = get url
      raise NonexistentUser, "'#{username}' does not exist" unless res.status == 200

      next_url = get_next_url res

      if next_url
        get_pages next_url, collection + res.body
      else
        collection + res.body
      end
    end

    def get_next_url(response)
      link_header = response.headers['link']
      if link_header
        match_data = link_header.match /<(.*page=\d+)>; rel="next"/
        return match_data[1] if match_data
      end

      nil
    end
  end

end
