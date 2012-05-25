module Tagore
  class Deployer
    START_PORT = 5000

    def self.run!
      deployer = self.new
      deployer.looper
    end

    def initialize
      option_parser

      @redis = Redis.new

      Tagore::Core::Service.host = @server

      @services = {}

      puts "#{@server} - #{@deploy_dir}"
    end

    def option_parser
      OptionParser.new do |opts|
        opts.banner = "Usage: #{__FILE__} [options]"

        opts.on("-s", "--server SERVER", "The server which will be out master") do |server|
          @server = server
        end

        opts.on("-d", "--deploy-dir DEPLOY_DIR", "WHere files should be deployed to") do |deploy_dir|
          @deploy_dir = deploy_dir
        end

        opts.on("-p", "--port PORT", "WHere files should be deployed to") do |port|
          @current_port = port
        end
      end.parse!

      @server = "http://127.0.0.1:3001" unless @server
      @current_port = START_PORT unless @current_port

      unless @deploy_dir
        puts "Deploy dir is not set"
        exit
      end
    end

    # TODO: Need to actually prevent deployment if the servier is out of
    # space.
    def can_deploy?
      #    @user_ports.size
      true
    end

    def deploy(service_id, commit)
      service = Tagore::Core::Service.info(service_id)
      @current_port += 1000

      deploy = Core::Deploy.new(@deploy_dir, service, commit, @current_port)
      deploy.setup
      deploy.stop_foreman(@services[service_id])
      deploy.deploy
      deploy.notify_server

      @services[service_id] = deploy.fork_and_run
    end

    def looper
      @redis.subscribe(:deploy) do |on|
        on.subscribe do |channel, subscriptions|
          puts "Subscribed to ##{channel} (#{subscriptions} subscriptions)"
        end

        on.message do |channel, message|
          puts "##{channel}: #{message}"

          if message =~ /(\w+) (\w+)/
            service_id = $1
            commit = $2

            puts "#{$1} - #{$2}"

            deploy(service_id, commit) if can_deploy?
          end
        end

        on.unsubscribe do |channel, subscriptions|
          puts "Unsubscribed from ##{channel} (#{subscriptions} subscriptions)"
        end
      end
    end
  end
end
