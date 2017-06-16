
module SolarPower
  class EGaugeClient
    def self.connection
      @connection ||= Faraday.new do |conn|
        conn.response :raise_error
        # conn.response :logger
        conn.response :parse_xml

        conn.adapter Faraday.default_adapter
      end
    end

    def initialize(url, username, password)
      @connection = self.class.connection.dup.tap do |conn|
        conn.url_prefix                = url
        conn.basic_auth username, password
      end
    end
    
    
    
  end
end