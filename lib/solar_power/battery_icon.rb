require 'chunky_png'

module SolarPower
  class BatteryIcon
    def initialize(percentage)
      @percentage = [ percentage, 100 ].min.to_i
      @image      = ChunkyPNG::Image.new(8, 8, ChunkyPNG::Color::TRANSPARENT)
    end

    def png
      outline
      power

      @image.to_blob
    end

    def outline
      grey = ChunkyPNG::Color(0xddddddff)

      @image[3, 0] = grey
      @image[4, 0] = grey
      @image.rect(2, 1, 5, 7, grey)
    end

    def power
      green   = ChunkyPNG::Color(0x22aa13ff)

      # Start at a y of 6 and end at 2
      ys      = 6.downto(2).to_a

      scaled  = @percentage / 100.0 * 5.0
      full    = scaled.floor
      partial = scaled % 1.0

      # Color in the full lines of green
      ys.shift(full).each do |y|
        @image[3, y] = green
        @image[4, y] = green
      end

      if (y = ys.shift) && partial > 0.0
        # Darken the color
        h, s, l      = ChunkyPNG::Color.to_hsl(green)
        darker_green = ChunkyPNG::Color.from_hsl(h, s, l * partial)

        @image[3, y] = darker_green
        @image[4, y] = darker_green
      end
    end
  end
end