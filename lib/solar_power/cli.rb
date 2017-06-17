require 'configlet'
require 'base64'

require 'solar_power/battery_icon'
require 'solar_power/lametric_client'
require 'solar_power/egauge_client'
require 'solar_power/egauge_usage'

module SolarPower
  class Cli
    attr_reader :program_name

    def initialize(argv)
      @args         = argv.dup
      @program_name = File.basename($0)
    end

    def call
      Configlet.config :solar_power do
        default :poll_interval => 10 * 60

        munge(:poll_interval) { |v| v.to_i }
      end

      read_env_from_file(File.expand_path("~/.solar_power.env"))
      read_env_from_file(File.expand_path("../../../.env", __FILE__))
      read_env_from_file('.env')

      if @args.first == '--help'
        usage
        exit(0)
      end

      case command = @args.shift
      when 'write_image'
        write_image
      when 'update'
        update
      when 'solar_usage'
        solar_usage
      when 'run'
        run
      else
        puts "#{program_name}: '#{command}' is not a command. see '#{program_name} --help'."
        exit(1)
      end

      exit(0)
    end

    def usage
      puts "usage: #{program_name} <command> [<args>]"
      puts
      puts "  The available commands are:"
      puts "    write_image    Write a PNG of the battery image"
      puts
      puts "Options:"
      puts
      puts "  --help      This help message"
      puts
    end

    def write_image
      unless filename = @args.shift
        puts "You must specify a file to write to."
        puts

        puts "usage: #{program_name} write_image <file> [percentage]"
        exit(1)
      end

      if percentage = @args.shift
        percentage = percentage.to_i
      else
        percentage = 75
      end

      png = SolarPower::BatteryIcon.new(percentage).png

      File.open(filename, 'w') do |io|
        io << png
      end
    end

    def update
      assert_configlet_options(:lametric_url, :lametric_access_token)

      if percentage = @args.shift
        percentage = percentage.to_i
      else
        puts "You must specify a percentage."
        puts
        puts "usage: #{program_name} update <percentage>"
        exit(1)
      end

      client = SolarPower::LaMetricClient.new(
        Configlet[:lametric_url], Configlet[:lametric_access_token])

      icon = SolarPower::BatteryIcon.new(percentage)

      client.update :frames => [
        {
          :text => "#{percentage}%",
          :icon => "data:image/png;base64,#{Base64.encode64(icon.png)}",
          :index => 0
        }
      ]
    end

    def solar_usage
      assert_configlet_options(:lametric_url, :lametric_access_token,
        :egauge_url, :egauge_user, :egauge_password)

      lametric = SolarPower::LaMetricClient.new(
        Configlet[:lametric_url], Configlet[:lametric_access_token])

      egauge = SolarPower::EGaugeClient.new(
        Configlet[:egauge_url], Configlet[:egauge_user],
        Configlet[:egauge_password])

      egauge_usage = egauge.total_usage
      percentage   = egauge_usage.percentage_generated.to_i

      icon = SolarPower::BatteryIcon.new(percentage)

      lametric.update :frames => [
        {
          :text => "#{percentage}%",
          :icon => "data:image/png;base64,#{Base64.encode64(icon.png)}",
          :index => 0
        }
      ]

      puts "Used #{egauge_usage.used.round(1)} kWh. Generated #{egauge_usage.generated.round(1)} kWh. Updated LaMetric to #{percentage}%"
    end

    def run
      assert_configlet_options(:lametric_url, :lametric_access_token,
        :egauge_url, :egauge_user, :egauge_password)

      lametric = SolarPower::LaMetricClient.new(
        Configlet[:lametric_url], Configlet[:lametric_access_token])

      egauge = SolarPower::EGaugeClient.new(
        Configlet[:egauge_url], Configlet[:egauge_user],
        Configlet[:egauge_password])

      while true
        egauge_usage = nil
        begin
          egauge_usage = egauge.total_usage
        rescue Faraday::TimeoutError
          puts "No response from eGauge"
          sleep 1
          next
        rescue Faraday::ConnectionFailed => e
          puts "Couldn't fetch data from eGauge: #{e.message}"
          sleep 1
          next
        end

        percentage = egauge_usage.percentage_generated.to_i

        icon = SolarPower::BatteryIcon.new(percentage)

        begin
          lametric.update :frames => [
            {
              :text => "#{percentage}%",
              :icon => "data:image/png;base64,#{Base64.encode64(icon.png)}",
              :index => 0
            }
          ]
        rescue Faraday::TimeoutError
          puts "No response from LaMetric"
          sleep 1
          next
        rescue Faraday::ConnectionFailed => e
          puts "Couldn't update LaMetric: #{e.message}"
          sleep 1
          next
        end

        puts "Used #{egauge_usage.used.round(1)} kWh. Generated #{egauge_usage.generated.round(1)} kWh. Updated LaMetric to #{percentage}%"

        sleep Configlet[:poll_interval]
      end
    end

    def assert_configlet_options(*options)
      messages = []

      options.flatten.uniq.each do |option|
        unless Configlet[option]
          messages << "#{Configlet.prefix.upcase}_#{option.upcase}= must be defined"
        end
      end

      unless messages.empty?
        puts messages.join("\n")
        exit(1)
      end
    end

    def read_env_from_file(filename)
      if File.exists?(filename)
        IO.read(filename).split(/\n+/).each do |line|
          ENV[$1] = $2 if line =~ /^([^#][^=]*)=(.+)$/
        end
      end
    end
  end
end