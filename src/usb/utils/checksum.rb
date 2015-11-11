class Usb::Utils::Checksum
  def self.load(hexdump)
    c = new
    c.load(hexdump)
    c
  end

  attr_reader :checksum

  def initialize
    @checksum = 0
  end

  def reset
    @checksum = 0
  end


  def <<(data)
    @checksum ^= data.to_i(16)
  end

  def dump
    @checksum.to_s(16)
  end

  def load(hexdump)
    @checksum = hexdump.to_i(16)
  end
end
