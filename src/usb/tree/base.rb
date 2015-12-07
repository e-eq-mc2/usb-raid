module Usb::Tree::Base

  module ClassMethods
    def write(key, str)
      Usb::Tree.storage[key] = str
    end

    def read(key)
      Usb::Tree.storage[key]
    end

    def load(meta)
      type   = meta.fetch(:type   )
      digest = meta.fetch(:digest )

      case type
      when Usb::Tree::Commit.type then Usb::Tree::Commit.do_load(digest)
      when Usb::Tree::Node.type   then Usb::Tree::Node.do_load(digest)
      when Usb::Tree::Blob.type   then Usb::Tree::Blob.do_load(digest)
      else fail
      end
    end

    def do_load(key)
      str = read(key) 
      return nil if str.nil?

      core = unpack(str)
      core.symbolize_keys!

      obj = new(core)
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

  def setxattr(name, data, flags)
    @xattr[name] = data #TODO:don't ignore flag
    save
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
    self.class.type
  end

  def dump
    h = to_h
    str  = self.class.pack(h)
  end

  def to_digest
    core = to_core
    str = self.class.pack(core)
    digest = Usb::Utils::Digest.hex(str)
  end

  def digest
    to_digest
  end

  def save
    str    = dump
    digest = to_digest

    self.class.write(digest, str)

    digest
  end

  def to_s
    "#{type}: digest=#{digest} core=#{to_core}"
  end

end
