require 'rubygems'
require "redis"
require 'erb'
require 'typhoeus'
require 'json'
require 'ruby-debug'

module Tagore
  NGINX_EXEC = "/usr/local/bin/nginx"
  SERVICES_URL = "http://localhost:3001/services.json"

  class Router

    def self.run!
      deployer = self.new
      deployer.looper
    end

    def initialize
      option_parser

      @redis = Redis.new
      @services = []

      puts "#{@server} - #{@nginx_file}"

      provision
    end

    def option_parser
      OptionParser.new do |opts|
        opts.banner = "Usage: #{__FILE__} [options]"

        opts.on("-s", "--server SERVER", "The server which will be out master") do |server|
          @server = server
        end

        opts.on("-f", "--file NGINX_FILE", "nginx.conf file") do |nginx_file|
          @nginx_file = nginx_file
        end
      end.parse!
    end

    def update_services
      response = Typhoeus::Request.get(SERVICES_URL)
      @services = JSON.parse(response.body)
    end
    private :update_services

    def generate_config
      file = File.open('nginx.conf.erb').read
      template = ERB.new(file)
      services = @services
      @config = template.result(binding)
    end
    private :generate_config

    def update_config_file
      File.open('nginx.conf', 'w+') do |f|
        f << @config
      end
    end
    private :update_config_file

    def provision
      update_services
      generate_config
      update_config_file
      # Check if the nginx file is valid.
      # Update the symlink to the new nginx file
      unless `#{NGINX_EXEC} -s reload`.empty?
        puts "uh oh"
      end
    end

    def looper
      @redis.subscribe(:nginx_provision) do |on|
        on.subscribe do |channel, subscriptions|
          puts "Subscribed to ##{channel} (#{subscriptions} subscriptions)"
        end

        on.message do |channel, message|
          puts "##{channel}: #{message}"
          provision

          redis.unsubscribe if message == "exit"
        end

        on.unsubscribe do |channel, subscriptions|
          puts "Unsubscribed from ##{channel} (#{subscriptions} subscriptions)"
        end
      end
    end
  end
end
