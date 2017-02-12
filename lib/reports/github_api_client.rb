require 'faraday'
require 'json'
require 'logger'

module Reports

  class Error < StandardError; end
  class NonexistentUser < Error; end
  class RequestFailure < Error; end

  VALID_STATUS_CODES = [200, 302, 403, 422]
  User = Struct.new :name, :location, :public_repos

  class GitHubAPIClient
    def initialize
      level = ENV['LOG_LEVEL']
      @logger = Logger.new STDOUT
      @logger.formatter = proc do |severity, datetime, program, message|
        message + "\n"
      end
    end

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

    private

    def get(url)
      start_time = Time.now
      response = Faraday.new.get url
      duration = Time.now - start_time

      @logger.debug '-> %s %s %d (%.3f s)' % [url, 'GET', response.status, duration]

      response
    end
  end

end
