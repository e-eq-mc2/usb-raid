class Usb::Tree::Node
  include Usb::Tree::Base

  class << self
    def type 
      'node'
    end
  end

  def initialize(
    mode:,
    uid:,
    gid:,
    actime:     nil,
    modtime:    nil,
    xattr:      nil,
    children:   nil,
    type:       nil
  )
    fail if type && type != self.type

    @mode     = mode
    @uid      = uid
    @gid      = gid

    @actime   = actime   || Time.now
    @modtime  = modtime  || Time.now
    @xattr    = xattr    || {}
    @children = children || {}
  end

  def stat
    RFuse::Stat.directory(mode, uid: uid, gid: gid, atime: actime, mtime: modtime, size: size)
  end

  def size
    @children.values.reduce(0) {|sum,c| sum + c[:size]}
  end

  def dir?
    true
  end

  def save
    digest = super

    digest
  end

  def insert_child(obj, name)
    @children[name] = obj.to_meta

    save

    obj
  end

  def read_child(name)
    child = @children[name]
    return nil if child.nil?

    self.class.load(child) || fail #Note: Data Lost!!!!j:w
  end

  def read_children
    children = {}

    @children.each_key do |name|
      obj = read_child(name)
      children[name] = obj
    end

    children
  end

  def read_each_child(&block)
    children = read_children 
    children.each &block
  end

  def remove_child(name)
    child = @children.delete(name)

    save

    child
  end

  def to_core
    {
      type:     type,
      uid:      @uid,
      gid:      @gid,
      mode:     @mode,
      xattr:    @xattr,
      children: @children,
    }
  end

  def to_h
    {
      type:     type,
      uid:      @uid,
      gid:      @gid,
      mode:     @mode,
      actime:   @actime,
      modtime:  @modtime,
      xattr:    @xattr,
      children: @children,
    }
  end

  def to_meta
    {
      type:   type,
      size:   size,
      digest: digest,
    }
  end

  def to_h_recursively(name:)
    {
      type:    type,
      uid:     @uid,
      gid:     @gid,
      mode:    @mode,
      actime:  @actime,
      modtime: @modtime,
      xattr:   @xattr,
      size:    size,
      digest:  digest,
      name:    name,
      children: read_each_child.map do |name, child|
        child.to_h_recursively(name: name)
      end
    }
  end


end


