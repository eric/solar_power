
require 'faraday'
require 'faraday_middleware'


module SolarPower
  class LaMetricClient
    def self.connection
      @connection ||= Faraday.new do |conn|
        conn.request :json
        conn.response :raise_error
        # conn.response :logger
        conn.response :json, :content_type => /\bjson$/
        conn.response :mashify

        conn.adapter Faraday.default_adapter

        conn.options.timeout = 5 # open/read timeout in seconds
      end
    end

    def initialize(url, access_token)
      @connection = self.class.connection.dup.tap do |conn|
        conn.url_prefix                = url
        conn.headers['Accept']         = 'application/json'
        conn.headers['X-Access-Token'] = access_token
        conn.ssl[:verify]              = false
      end
    end

    def update(data)
      @connection.post '' do |req|
        req.body = data
      end
    end
  end
end