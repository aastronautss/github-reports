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

    desc 'repositories USERNAME', 'List user\'s public repositories'
    option :forks, type: :boolean, desc: "Include forks in stats", default: false
    def repositories(username)
      puts "Fetching repository statistics for #{username}..."

      user_repos = client.public_repos_for_user username, forks: options[:forks]

      table_printer = TablePrinter.new(STDOUT)

      user_repos.each do |repo|
        table_printer.print(repo.languages, title: repo.full_name, humanize: true)
        puts # blank line
      end

      stats = Hash.new(0)
      user_repos.each do |repo|
        repo.languages.each_pair do |language, bytes|
          stats[language] += bytes
        end
      end

      table_printer.print(stats, title: "Language Summary", humanize: true, total: true)

      puts "\n#{username} has #{user_repos.count} public repos."
    rescue Error => e
      puts "ERROR #{e.message}"
      exit 1
    end

    desc 'activity USERNAME', 'Get a user\'s recent activity'
    def activity(username)
      puts "Getting recent activity for #{username}..."

      user_events = client.public_activity_for_user username
      puts "Fetched #{user_events.count} events.\n\n"

      print_activity_report user_events
    rescue Error => e
      puts "ERROR #{e.message}"
      exit 1
    end

    private

    def client
      @client ||= GitHubAPIClient.new
    end

    def print_activity_report(events)
      table_printer = TablePrinter.new STDOUT
      event_types_map = events.each_with_object(Hash.new 0) do |event, counts|
        counts[event.type] += 1
      end

      table_printer.print(event_types_map, title: "Event Summary", total: true)

      push_events = events.select { |event| event.type == "PushEvent" }
      push_events_map = push_events.each_with_object(Hash.new 0) do |event, counts|
        counts[event.repo_name] += 1
      end

      puts
      table_printer.print push_events_map, title: 'Project Push Summary', total: true
    end

  end

end
