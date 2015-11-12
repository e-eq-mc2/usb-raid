module Usb::Tree::Base
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

end
