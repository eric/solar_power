
require 'faraday'
require 'faraday_middleware'


module SolarPower
  class LaMetricClient
    def self.connection
      @connection ||= Faraday.new do |conn|
        conn.request :json
        conn.response :json, :content_type => /\bjson$/
        conn.response :mashify
      end
    end

    def initialize()
    end
  end
end