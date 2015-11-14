class Usb::Tree::Blob
  include Usb::Tree::Base

  class << self
    def type 
      'blob'
    end
  end

  attr_accessor :content

  def initialize(
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

    @mode    = mode

    @uid     = uid
    @gid     = gid

    @actime  = actime  || 0
    @modtime = modtime || 0
    @xattr   = xattr   || Hash.new

    @content = content || ""
  end

  def stat
    RFuse::Stat.file(mode, uid: uid, gid: gid, atime: actime, mtime: modtime, size: size)
  end

  def size
    content.size
  end

  def write(data:, offset: 0)
    length = offset + data.length - 1
    range  = offset..length
    @content[range] = data

    save

    data.bytesize
  end

  def truncate(length)
    range = 0..length
    @content = @content[length]

    save

    length
  end

  def read(offset:, size:)
    length = offset + size - 1
    range  = offset..length

    data = @content[range]

    data
  end

  def dir?
    false
  end

  def follow(path_array, ancestors: nil)
    ancestors << self if ancestors

    if path_array.length != 0 then
      raise Errno::ENOTDIR.new
    else
      return self
    end
  end

  def to_core
    {
      type:     type,
      uid:      @uid,
      gid:      @gid,
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
      digest: digest
    }
  end

end


