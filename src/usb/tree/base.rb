module Usb::Tree::Base

  module ClassMethods
    attr_accessor :data_path

    def storage
      path = data_path || fail
      @storage ||= Usb::Utils::FsHash.new(path, persistent: true)
    end

    def write(key, str)
      storage[key] = str
    end

    def read(key)
      storage[key]
    end

    def load(key)
      str = read(key) 
      return nil if str.nil?

      core = unpack(str)

      obj  = new(core)
    end

    def pack(core)
      Usb::Utils::Serializer.pack(core, format: format)
    end

    def unpack(str)
      Usb::Utils::Serializer.unpack(str, format: format)
    end

    def format
      :marshal
    end

  end

  def self.included(base)
    base.extend(ClassMethods)
  end


  attr_accessor :name, :mode , :actime, :modtime, :uid, :gid

  def listxattr
    @xattr.keys
  end

  def setxattr(name, value, flag)
    @xattr[name]=value #TODO:don't ignore flag
  end

  def getxattr(name)
    return @xattr[name]
  end

  def removexattr(name)
    @xattr.delete(name)
  end

  def file?
    ! dir?
  end

  def type
    dir? ? 'node' : 'blob'
  end

  def dump
    core   = to_core
    str    = self.class.pack(core)
  end

  def to_digest(str = nil)
    str ||= dump
    digest = Usb::Utils::Digest.hex(str)
  end

  def digest
    to_digest
  end

  def save
    str    = dump
    digest = to_digest(str)

    self.class.write(digest, str)
  end

end
