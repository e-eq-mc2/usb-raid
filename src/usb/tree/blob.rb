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

    @actime  = actime  || Time.now
    @modtime = modtime || Time.now
    @xattr   = xattr   || {}
    @content = content || ''
  end

  def stat
    RFuse::Stat.file(mode, uid: uid, gid: gid, atime: actime, mtime: modtime, size: size)
  end

  def size
    @content.bytesize
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
    @content = @content[range]

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

  def to_core
    {
      type:     type,
      uid:      @uid,
      gid:      @gid,
      mode:     @mode,
      actime:   @actime,
      modtime:  @modtime,
      xattr:    @xattr,
      content:  @content,
    }
  end

  def to_meta
    {
      type:   type,
      size:   size,
      digest: digest
    }
  end

end


