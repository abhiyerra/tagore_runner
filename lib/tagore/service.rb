module Tagore
  class Service
    include HTTParty

    def available_ports

    end

    def info(service_id)
      response = Typhoeus::Request.get(@service_url + service_id + ".json")
      service = JSON.parse(response.body)
    end
  end
end
