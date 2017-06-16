require 'multi_xml'
require 'faraday'
require 'faraday_middleware'
require 'faraday/digestauth'

module SolarPower
  class EGaugeClient
    def self.connection
      @connection ||= Faraday.new do |conn|
        # conn.response :raise_error
        # conn.response :logger
        conn.response :xml, :content_type => /\bxml$/

        conn.adapter Faraday.default_adapter
      end
    end

    def initialize(url, username, password)
      @connection = self.class.connection.dup.tap do |conn|
        conn.url_prefix = url
        conn.digest_auth username, password

        conn.options.timeout = 5 # open/read timeout in seconds
      end
    end

    def show(options)
      @connection.get("/cgi-bin/egauge-show?#{options}")
    end

    def total_usage
      # Invoke a request with the options:
      #
      #   * a: Requests that the totals and virtual registers calculated from the physical register
      #        values be included as the first columns in each row
      #   * C: Specifies that the returned data be delta-compressed
      #   * d: Specifies that n and s parameters are specified in units of days
      #   * e: Requests the output of one extra data point beyond the requested range
      #   * n: Specifies the maximum number of rows to be returned
      response = show 'a&C&d&e&n=1'

      unless response.success?
        raise "Could not get data from eGauge: #{response.status}: #{response.body}"
      end

      SolarPower::EGaugeUsage.new(response)
    end
  end
end