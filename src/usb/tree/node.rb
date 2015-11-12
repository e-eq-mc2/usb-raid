class Usb::Tree::Node
  include Usb::Tree::Base

  class << self
    def type 
      'node'
    end

    def load_HEAD
      digest = read('HEAD')

      do_load(digest) if digest
    end
  end

  def initialize(
    name:, 
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

    @name    = name
    @mode    = mode


    @uid     = uid     || 0
    @gid     = gid     || 0
    @actime  = actime  || Time.now
    @modtime = modtime || Time.now
    @xattr   = xattr   || Hash.new

    @child_metas = child_metas || {}
  end

  def stat
    RFuse::Stat.directory(mode,:uid => uid, :gid => gid, :atime => actime, :mtime => modtime, :size => size)
  end

  def size
    return 48 #for testing only
  end

  def dir?
    true
  end

  def root?
    @name == ""
  end

  def insert_child(obj)
    obj.save
    child_meta = obj.to_meta
    @child_metas[obj.name] = child_meta

    save
  end

  def remove_child(name)
    @child_metas.delete(name)

    save
  end

  def save
    digest = super
    self.class.write('HEAD', digest) if root?

    digest
  end

  def load_children
    children = {}

    each_meta do |name, meta|
      child = self.class.load(meta)
      children[name] = child
    end

    children
  end

  def each(&block)
    children = load_children 
    children.each &block
  end

  def each_meta(&block)
    @child_metas.each &block
  end

  def insert(obj, path)
    parent_path = File.dirname(path)

    ancestors = []
    parent = search(parent_path, ancestors: ancestors)
    
    raise Errno::ENOTDIR.new(parent.name) if not parent.dir?

    child = obj
    ancestors.reverse.each do |cur|
      cur.insert_child(child)
      child = cur
    end

    parent
  end

  def remove(path)
    parent_path = File.dirname(path)

    ancestors = []
    parent = search(parent_path, ancestors: ancestors)
    
    raise Errno::ENOTDIR.new(parent.name) if not parent.dir?

    child_name = File.basename(path)
    parent.remove_child(child_name)

    ancestors.pop

    child = parent
    ancestors.reverse.each do |cur|
      cur.insert_child(child)
      child = cur
    end
  end

  def write(path, data:, offset:)
    parent_path = File.dirname(path)

    ancestors = []
    blob = search(path, ancestors: ancestors)

    raise Errno::EISDIR.new(path) if not blob.file?

    length = blob.write(data: data, offset: offset)

    ancestors.pop

    child = blob
    ancestors.reverse.each do |cur|
      cur.insert_child(child)
      child = cur
    end

    length
  end

  def truncate(path, last:)
    ancestors = []
    blob = search(path, ancestors: ancestors)
    blob.truncate(last)

    ancestors.pop

    child = blob
    ancestors.reverse.each do |cur|
      cur.insert_child(child)
      child = cur
    end

    last
  end

  def read(path, offset: 0, size:)
    blob = search(path)
    raise Errno::EISDIR.new(path) if not blob.file?

    blob.read(offset: offset, size: size)
  end

  def search(path, ancestors: nil)
    path_array = path.split('/')

    path_array.shift #Note: drop root("")

    obj = follow(path_array, ancestors: ancestors)
    return obj
  end

  def follow(path_array, ancestors: nil)
    ancestors << self if ancestors

    if path_array.empty? #Note: leaf
      return self
    else
      child_name = path_array.shift
      child_meta = @child_metas[ child_name ]

      if child_meta
        child = self.class.load(child_meta) || fail

        return child.follow(path_array, ancestors: ancestors)
      else
        raise Errno::ENOENT.new
      end
    end
  end

  def to_s
    return "Dir: " + @name + "(" + @mode.to_s + ")"
  end

  def to_core
    {
      type:        type,
      uid:         @uid,
      gid:         @gid,
      actime:      @actime,
      modtime:     @modtime,
      xattr:       @xattr,
      name:        @name,
      mode:        @mode,
      child_metas: @child_metas,
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


