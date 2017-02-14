require 'dotenv'
Dotenv.load

require 'rubygems'
require 'bundler/setup'
require 'thor'

require 'reports/github_api_client'
require 'reports/table_printer'

module Reports

  class CLI < Thor

    desc "console", "Open an RB session with all dependencies loaded and API defined."
    def console
      require 'irb'
      ARGV.clear
      IRB.start
    end

    desc 'repositories USERNAME', 'List user\'s public repositories'
    def repositories(username)
      puts "Fetching repository statistics for #{username}..."

      user_repos = client.public_repos_for_user username

      puts "#{username} has #{user_repos.count} public repos."
      puts ' '

      user_repos.each do |repo|
        puts "#{repo.full_name} - #{repo.svn_url}"
      end
    rescue Error => e
      puts "ERROR #{e.message}"
      exit 1
    end

    desc 'user_info USERNAME', 'Get information for a user'
    def user_info(username)
      puts "Getting info for #{username}..."

      user = client.get_user username

      puts "name: #{user.name}"
      puts "location: #{user.location}"
      puts "public repos: #{user.public_repos}"
    rescue Error => e
      puts "ERROR #{e.message}"
      exit 1
    end

    private

    def client
      @client ||= GitHubAPIClient.new(ENV['GITHUB_TOKEN'])
    end

  end

end
