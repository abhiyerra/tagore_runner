module Tagore
  module Core
    class Service
#      include HTTParty

      @@host = ""

      def self.host
        @@host
      end

      def self.host=(host)
        @@host = host
      end


      def available_ports

      end

      def self.info(service_id)
        response = Typhoeus::Request.get(self.host + "/services/" + service_id + ".json")
        service = JSON.parse(response.body)
      end
    end
  end
end
