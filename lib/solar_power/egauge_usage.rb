
module SolarPower
  class EGaugeUsage
    def initialize(response)
      @response = response
      @values = {}
      process
    end

    def get(key)
      @values[key]
    end

    def used
      @values['use']
    end

    def generated
      @values['gen']
    end

    def percentage_generated
      generated / used * 100
    end

    def process
      @response.body['group']['data']['cname'].each_with_index do |cname, idx|
        name = cname['__content__']
        value = @response.body['group']['data']['r'][1]['c'][idx]

        if cname['t'] == 'P'
          # Because the delta-compressed data is ordered from newest to
          # oldest, it requires inverting the number
          value = value.to_i * -1

          # The data in the register is represented in Watt-seconds
          # and must be divided by 3,600,000 to get kilo-Watt-hours
          value /= 3_600_000.0
        end

        @values[name] = value
      end
    end
  end
end