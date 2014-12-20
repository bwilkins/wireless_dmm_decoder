#!/usr/bin/env ruby

require 'rubyserial'

class MultimeterScreen
  attr_accessor :ac, :dc, :auto, :wireless, :negative,
                :a1, :a2, :a3, :a4, :a5, :a6, :a7,
                :b1, :b2, :b3, :b4, :b5, :b6, :b7,
                :c1, :c2, :c3, :c4, :c5, :c6, :c7,
                :d1, :d2, :d3, :d4, :d5, :d6, :d7,
                :p1, :p2, :p3,
                :micro, :nano, :kilo, :diode,
                :milli, :percent, :mega, :sound,
                :farads, :ohms, :rel, :hold,
                :amperes, :volts, :hertz, :battery,
                :_, :celcius, :fahrenheit

  LINES = {
    0b0001 => [:ac, :dc, :auto, :wireless],
    0b0010 => [:negative, :a5, :a6, :a1],
    0b0011 => [:a4, :a3, :a7, :a2],
    0b0100 => [:p1, :b5, :b6, :b1],
    0b0101 => [:b4, :b3, :b7, :b2],
    0b0110 => [:p2, :c5, :c6, :c1],
    0b0111 => [:c4, :c3, :c7, :c2],
    0b1000 => [:p3, :d5, :d6, :d1],
    0b1001 => [:d4, :d3, :d7, :d2],
    0b1010 => [:micro, :nano, :kilo, :diode],
    0b1011 => [:milli, :percent, :mega, :sound],
    0b1100 => [:farads, :ohms, :rel, :hold],
    0b1101 => [:amperes, :volts, :hertz, :battery],
    0b1110 => [:_, :_, :celcius, :fahrenheit],
  }

  DIGITS = {
   #[:a1,   :a2,   :a3,   :a4,   :a5,   :a6,   :a7]
    [true,  true,  true,  true,  true,  true,  false] => 0,
    [false, true,  true,  false, false, false, false] => 1,
    [true,  true,  false, true,  true,  false, true ] => 2,
    [true,  true,  true,  true,  false, false, true ] => 3,
    [false, true,  true,  false, false, true,  true ] => 4,
    [true,  false, true,  true,  false, true,  true ] => 5,
    [true,  false, true,  true,  true,  true,  true ] => 6,
    [true,  true,  true,  false, false, false, false] => 7,
    [true,  true,  true,  true,  true,  true,  true ] => 8,
    [true,  true,  true,  true,  false, true,  true ] => 9
  }

  def update(line_id, line_data)
    line_vars = LINES[line_id]
    puts line_id, line_data
    return if line_vars.nil?
    pairs = line_vars.zip(line_data)
    pairs.each do |var, data|
      send("#{var}=", data)
    end
  end

  def decode_cell(cell_id)
    cell_states = (1..7).map do |num|
      send("#{cell_id}#{num}")
    end

    DIGITS[cell_states]
  end

  def sign
    negative ? '-' : ''
  end

  def dec_1
    p1 ? '.' : ''
  end

  def dec_2
    p2 ? '.' : ''
  end

  def dec_3
    p3 ? '.' : ''
  end

  def cell_a
    decode_cell(:a)
  end

  def cell_b
    decode_cell(:b)
  end

  def cell_c
    decode_cell(:c)
  end

  def cell_d
    decode_cell(:d)
  end

  def decode_number
    "#{sign}#{cell_a}#{dec_1}#{cell_b}#{dec_2}#{cell_c}#{dec_3}#{cell_d}"
  end

end

class SerialToScreen
  def initialize(port, screen = MultimeterScreen.new)
    @port = port
    @screen = screen
  end

  def update
    (1..14).each do |i|
      line_id, data = read_line(i)
      screen.update(line_id, data)
    end
  end

  def read_line(line_num)
    loop do
      line = port.read(1)
      next if line == ""
      bits = line.unpack('B*').first
      line_id = bits[0..3].to_i(2)
      next if line_id != line_num
      data = bits[4..7].split('').map do |d|
        d.to_i == 1 ? true : false
      end
      return [line_id, data]
    end
  end

  def flush
    loop do
      return if port.read(1024) == ''
    end
  end

  attr_reader :port, :screen
end

# port = Serial.new('/dev/cu.SLAB_USBtoUART', 2400)
# dmm = MultimeterScreen.new
# ss = SerialToScreen.new(port, dmm)
# ss.flush
# ss.update
# dmm.decode_number
