module Tagore
  module Core
    class Service
      include HTTParty

      @@host = ""

      base_uri @@host

      def self.host
        @@host
      end

      def self.host=(host)
        @@host = host
      end

      def self.services
        response = get("/services.json")
        JSON.parse(response.body)
      end

      def self.started!(service_id, port)
        post("/services/#{service_id}/started", :params => {
            # :machine_id => machine_id,
            :port => port
          })
      end

      def self.killed!(service_id, port)
        post("/services/#{service_id}/killed", :params => {
            # :machine_id => "",
            :port => port
          })
      end

      def self.info(service_id)
        response = get("/services/#{service_id}.json")
        service = JSON.parse(response.body)
      end
    end
  end
end
