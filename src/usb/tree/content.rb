class Usb::Tree::Content
  include Usb::Tree::Base

  class << self
    def type 
      'content'
    end

    def format
      :marshal
    end
  end

  def initialize(data)
    @data
  end

  def size
    @data.bytesize
  end

  def write(data:, offset: 0)
    length = offset + data.length - 1
    range  = offset..length
    @data[range] = data

    save

    data.bytesize
  end

  def truncate(length)
    range = 0..length
    @data = @data[length]

    save

    length
  end

  def read(offset:, size:)
    length = offset + size - 1
    range  = offset..length

    @data[range]
  end

  def dir?
    false
  end

  def to_core
    @data
  end

  def to_meta
    {
      type:   type,
      digest: digest
    }
  end



end
