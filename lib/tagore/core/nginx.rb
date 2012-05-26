module Tagore
  module Core
    class Nginx
      EXEC = "/usr/local/bin/nginx"

      def initialize(nginx_erb, nginx_conf)

      end

      def generate
        file = File.open(@nginx_conf).read
        template = ERB.new(file)
        services = @services
        @config = template.result(binding)
      end

      def save!
        File.open(@nginx_file, 'w+') do |f|
          f << @config
        end
      end

      # TODO: Check if the nginx file is valid.  Update the symlink to
      # the new nginx file
      def deploy!
        unless `#{NGINX_EXEC} -s reload`.empty?
          puts "uh oh"
        end
      end

    end
  end
end
