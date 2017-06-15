require 'configlet'
require 'base64'

require 'solar_power/battery_icon'
require 'solar_power/lametric_client'

module SolarPower
  class Cli
    attr_reader :program_name

    def initialize(argv)
      @args         = argv.dup
      @program_name = File.basename($0)
    end

    def call
      Configlet.prefix = 'solar_power'

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
      unless Configlet[:lametric_url]
        puts "SOLAR_POWER_LAMETRIC_URL= must be defined"
        exit(1)
      end

      unless Configlet[:lametric_access_token]
        puts "SOLAR_POWER_LAMETRIC_ACCESS_TOKEN= must be defined"
        exit(1)
      end

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

    def read_env_from_file(filename)
      if File.exists?(filename)
        IO.read(filename).split(/\n+/).each do |line|
          ENV[$1] = $2 if line =~ /^([^#][^=]*)=(.+)$/
        end
      end
    end
  end
end