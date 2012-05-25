module Tagore
  module Core
    class Deploy
      def initialize(deploy_dir, service, commit, port)
        @service = service
        @commit = commit
        @deploy_dir = deploy_dir
        @deploy_loc = "#{deploy_dir}#{@service["name"]}"
        @port = port
      end

      # Clone the repo if it's not already checked out.
      def setup
        unless File.directory?(@deploy_loc)
          puts `cd #{@deploy_dir} && git clone #{@service["repo"]} #{@service["name"]}`
        end
      end

      def deploy
        puts `cd #{@deploy_dir}#{@service["name"]} && git checkout master && git pull --rebase && git checkout #{@commit}`

        # TODO: Should start the forman service in a restricted mode so
        # other services can't fuck with things.
      end

      def fork_and_run
        fork do
          exec("cd #{@deploy_dir}#{@service["name"]} && PORT=#{@port} foreman start -c web=4 -p #{@port}")
        end
      end

    end
  end
end
