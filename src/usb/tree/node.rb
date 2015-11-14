class Usb::Tree::Node
  include Usb::Tree::Base

  class << self
    def type 
      'node'
    end
  end

  def initialize(
    mode:, 
    type:        nil,
    uid:         nil,
    gid:         nil,
    actime:      nil,
    modtime:     nil,
    xattr:       nil,
    child_metas: nil
  )
    fail if type && type != self.type

    @mode    = mode
    @uid     = uid     || 0
    @gid     = gid     || 0
    @actime  = actime  || Time.now
    @modtime = modtime || Time.now
    @xattr   = xattr   || Hash.new

    @child_metas = child_metas || {}
  end

  def stat
    RFuse::Stat.directory(mode, uid: uid, gid: gid, atime: actime, mtime: modtime, size: size)
  end

  def size
    return 48 #for testing only
  end

  def dir?
    true
  end

  def save
    digest = super

    digest
  end

  def set_child(child, name)
    @child_metas[name] = child.to_meta

    save

    child
  end

  def get_child(name)
    meta = @child_metas[name]
    return nil if meta.nil?

    self.class.load(meta) || fail #Note: Data Lost!!!!j:w
  end

  def get_children
    children = {}

    @child_metas.each_key do |name|
      child = get_child(name)
      children[name] = child
    end

    children
  end

  def each_child(&block)
    children = get_children 
    children.each &block
  end

  def remove_child(name)
    child = @child_metas.delete(name)

    save

    child
  end

  def to_core
    {
      type:        type,
      uid:         @uid,
      gid:         @gid,
      actime:      @actime,
      modtime:     @modtime,
      xattr:       @xattr,
      mode:        @mode,
      child_metas: @child_metas,
    }
  end

  def to_meta
    {
      type:   type,
      digest: digest,
    }
  end

end


