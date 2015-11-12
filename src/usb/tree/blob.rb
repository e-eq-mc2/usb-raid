class Usb::Tree::Blob
  include Usb::Tree::Base

  attr_accessor :content

  def initialize(name,mode,uid,gid)
    @name    = name
    @mode    = mode

    @uid     = uid
    @gid     = gid
    @actime  = 0
    @modtime = 0
    @xattr   = Hash.new

    @content = ""
  end

  def stat
    RFuse::Stat.file(mode,:uid => uid, :gid => gid, :atime => actime, :mtime => modtime, :size => size)
  end

  def size
    return content.size
  end

  def dir?
    false
  end

  def follow(path_array)
    if path_array.length != 0 then
      raise Errno::ENOTDIR.new
    else
      return self
    end
  end

  def to_s
    return "File: " + @name + "(" + @mode.to_s + ")"
  end

end


