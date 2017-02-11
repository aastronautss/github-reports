require 'faraday'
require 'json'

module Reports

  User = Struct.new :name, :location, :public_repos

  class GitHubAPIClient
    def get_user(username)
      response = get "https://api.github.com/users/#{username}"
      data = JSON.parse response.body
      User.new data['name'], data['location'], data['public_repos']
    end

    private

    def get(url)
      Faraday.new.get url
    end
  end

end
