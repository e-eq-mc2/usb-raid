class Usb::Tree::Node
  include Usb::Tree::Base

  attr_accessor :children

  def initialize(name,mode)
    @name    = name
    @mode    = mode

    @uid     = 0
    @gid     = 0
    @actime  = Time.now
    @modtime = Time.now
    @xattr   = Hash.new

    @children = {}
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

  def add(obj)
    @children[obj.name] = obj
  end

  def each(&block)
    @children.each &block
  end

  def insert_obj(obj,path)
    parent_path = File.dirname(path)
    parent = search(parent_path)
    if parent.dir? then
      parent.add(obj)
    else
      raise Errno::ENOTDIR.new(parent.name)
    end
    return parent
  end

  def remove_obj(path)
    d=self.search(File.dirname(path))
    d.delete(File.basename(path))
  end

  def search(path)
    path_array = path.split('/')

    path_array.shift #Note: drop root("")
    return follow(path_array)
  end

  def follow(path_array)
    if path_array.empty? #Note: leaf
      return self
    else
      child_name = path_array.shift

      child = @children[ child_name ]
      if child
        return child.follow(path_array)
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
      uid:     @uid,
      gid:     @gid,
      atime:   @actime,
      modtime: @modtime,
      xattr:   @xattr,
      name:    @name,
      mode:    @mode
    }
  end

  def to_digest
    core = to_core

    Usb::Utils::Digest.hex()
  end

end


