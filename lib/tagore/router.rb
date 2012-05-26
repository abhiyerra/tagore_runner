module Tagore
  class Router
    def self.run!
      router = self.new
      router.provision # Want to provision the first time around.
      router.looper
    end

    def initialize
      option_parser

      @redis = Redis.new
      @services = []

      puts "#{@server} - #{@nginx_erb}"
    end

    def option_parser
      OptionParser.new do |opts|
        opts.banner = "Usage: #{__FILE__} [options]"

        opts.on("-s", "--server SERVER", "The server which will be out master") do |server|
          @server = server
        end

        opts.on("-e", "--erb NGINX_ERB", "nginx.conf file") do |nginx_erb|
          @nginx_erb = nginx_erb
        end

        opts.on("-c", "--config NGINX_CONF_FILE", "nginx.conf file") do |nginx_conf|
          @nginx_conf = nginx_conf
        end
      end.parse!
    end

    def provision
      nginx = Tagore::Core::Nginx.new(@nginx_erb, @nginx_file)
      nginx.generate(Tagore::Core::Service.services)
      nginx.save!
      nginx.deploy!
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
