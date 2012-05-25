require 'rubygems'
require "redis"
require 'typhoeus'
require 'json'
require 'ruby-debug'
require 'optparse'

trap(:INT) { puts; exit }

DEPLOY_DIR = "/Users/abhi/deployer/"

class Deployer

  def initialize(server, deploy_dir)
    @redis = Redis.new
    @used_ports = {}
    @current_port = 5000

    @service_url = "#{$server}/services/"

    @services = {}
  end

  # TODO: Need to actually prevent deployment if the servier is out of
  # space.
  def can_deploy?
    #    @user_ports.size
    true
  end

  def deploy(service_id, commit)
    response = Typhoeus::Request.get(@service_url + service_id + ".json")

    service = JSON.parse(response.body)
    @current_port += 1000
    port = @current_port

    deploy_loc = "#{$deploy_dir}#{service["name"]}"
    # if not directory exists
    unless File.directory?(deploy_loc)
      puts `cd #{$deploy_dir} && git clone #{service["repo"]} #{service["name"]}`
    end

    puts `cd #{$deploy_dir}#{service["name"]} && git checkout master && git pull --rebase && git checkout #{commit}`
    # TODO: Create forman file

    # TODO: Should start the forman service in a restricted mode so
    # other services can't fuck with things.

    if @services[service_id]
      Process.kill "QUIT", @services[service_id]
#      puts `cd #{$deploy_dir}#{service["name"]} && foreman stop`
    end

    response = Typhoeus::Request.post(@service_url + service_id + "/posts")

    @services[service_id] = fork do
      exec("cd #{$deploy_dir}#{service["name"]} && PORT=#{port} foreman start -c web=4 -p #{port}")
    end

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


OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options]"

  opts.on("-s", "--server SERVER", "The server which will be out master") do |server|
    $server = server
  end

  opts.on("-d", "--deploy-dir DEPLOY_DIR", "WHere files should be deployed to") do |deploy_dir|
    $deploy_dir = deploy_dir
  end
end.parse!

$server = "http://127.0.0.1:3001" unless $server
$deploy_dir = DEPLOY_DIR unless $deploy_dir

puts "#{$server} - #{$deploy_dir}"

deployer = Deployer.new($server, $deploy_dir)
deployer.looper
