class Usb::Tree::Blob
  include Usb::Tree::Base

  class << self
    def type 
      'blob'
    end
  end

  attr_accessor :content

  def initialize(
    name:,
    mode:,
    uid:,
    gid:,
    actime:  nil,
    modtime: nil,
    xattr:   nil,
    content: nil,
    type:    nil
  )
    fail if type && type != self.type

    @name    = name
    @mode    = mode

    @uid     = uid
    @gid     = gid

    @actime  = actime  || 0
    @modtime = modtime || 0
    @xattr   = xattr   || Hash.new

    @content = content || ""
  end

  def stat
    RFuse::Stat.file(mode,:uid => uid, :gid => gid, :atime => actime, :mtime => modtime, :size => size)
  end

  def size
    return content.size
  end

  def write(data:, offset: 0)
    range = offset..(offset + data.length - 1)
    @content[range] = data

    save

    data.length
  end

  def read(offset:, size:)
    range = offset..offset + size - 1

    data = @content[range]

    data
  end

  def dir?
    false
  end

  def follow(path_array, ancestors: nil)
    if path_array.length != 0 then
      raise Errno::ENOTDIR.new
    else
      return self
    end
  end

  def to_s
    return "File: " + @name + "(" + @mode.to_s + ")"
  end

  def to_core
    {
      type:     type,
      uid:      @uid,
      gid:      @gid,
      name:     @name,
      mode:     @mode,
      content:  @content,
      actime:   @actime,
      modtime:  @modtime,
      xattr:    @xattr,
    }
  end

  def to_meta
    {
      type:   type,
      name:   name,
      digest: digest
    }
  end

end


