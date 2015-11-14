require 'rfuse'
require 'pry'

class Usb::Tree
end

require_relative 'tree/base'
require_relative 'tree/node'
require_relative 'tree/root'
require_relative 'tree/blob'

class Usb::Tree
  class << self
    attr_reader :storage

    def setup_storage(paths)
      @storage = Usb::Storage.new(paths)
    end
  end

  def initialize(root)
    @root = root
  end

  def log(str)
    puts str
  end

  # The new readdir way, c+p-ed from getdir
  def readdir(ctx, path, filler, offset, ffi)
    log "#{__method__} path: #{path}".blue

    obj = @root.search(path)

    raise Errno::ENOTDIR.new(path) if not obj.dir?

    obj.each_child do |name, obj|
      filler.push(name, obj.stat, 0)
    end
  end

  def getattr(ctx, path)
    log "#{__method__}: path=#{path}".blue

    obj = @root.search(path)
    obj.stat
  end

  def mkdir(ctx, path, mode)
    log "#{__method__}: path=#{path}".red

    obj = Node.new(mode: mode, uid: ctx.uid, gid: ctx.gid)
    @root.insert(obj, path)
  end

  def mknod(ctx,path,mode,major,minor)
    log "#{__method__}: path=#{path}".red
    
    obj = Blob.new(mode: mode, uid: ctx.uid, gid: ctx.gid)
    @root.insert(obj, path)
  end

  def open(ctx,path,ffi)
    log "#{__method__}: path=#{path}"
  end

  def release(ctx,path,fi)
    log "#{__method__}: path=#{path}"
  end

  def flush(ctx, path, fi)
    log "#{__method__}: path=#{path}"
  end

  def chmod(ctx,path,mode)
    log "#{__method__}: path=#{path}"
  end

  def chown(ctx,path,uid,gid)
    log "#{__method__}: path=#{path}"
  end

  def truncate(ctx, path, length)
    @root.truncate(path, length: length)
  end

  def utime(ctx,path,actime,modtime)
    log "#{__method__}: path=#{path}"
  end

  def unlink(ctx, path)
    log "#{__method__}: path=#{path}".red
    @root.remove(path)
  end

  def rmdir(ctx, path)
    log "#{__method__}: path=#{path}".red
    @root.remove(path)
  end

  def symlink(ctx,path,as)
    log "#{__method__}: path=#{path}"
  end

  def rename(ctx, from_path, to_path)
    log "from_path: #{from_path} to_path: #{to_path} #{__method__}".red

    obj = @root.search(from_path)

    @root.remove(from_path)
    @root.insert(obj, to_path)
  end

  def link(ctx,path,as)
    puts "path: #{path} #{__method__}".yellow
  end

  def read(ctx,path,size,offset,fi)
    @root.read(path, offset: offset, size: size)
  end

  def write(ctx, path, data, offset, fi)
    puts "path: #{path} #{__method__}".red
    @root.write(path, data: data, offset: offset)
  end

  def setxattr(ctx, path, name, data, flags)
    puts "path: #{path} #{__method__}".red
    @root.setxattr(path, name: name, data: data, flags: flags)
  end

  def getxattr(ctx,path,name)
    puts "path: #{path} #{__method__}".blue
    obj = @root.search(path)
    if obj
      value = obj.getxattr(name)
      if !value
        value=""
        #raise Errno::ENOENT.new #TODO raise the correct error :
        #NOATTR which is not implemented in Linux/glibc
      end
    else
      raise Errno::ENOENT.new
    end
    value 
  end

  def listxattr(ctx,path)
    puts "path: #{path} #{__method__}".blue
    obj = @root.search(path)
    value = obj.listxattr
  end

  def removexattr(ctx,path,name)
    puts "path: #{path} #{__method__}".blue
    d=@root.search(path)
    d.removexattr(name)
  end

  def opendir(ctx,path,ffi)
    puts "path: #{path} #{__method__}".blue
  end

  def releasedir(ctx, path, ffi)
    puts "#{__method__} path: #{path}".blue
  end

  def fsyncdir(ctx,path,meta,ffi)
    puts "path: #{path} #{__method__}".blue
  end

  # Some random numbers to show with df command
  def statfs(ctx,path)
    s = RFuse::StatVfs.new()
    s.f_bsize    = 1024
    s.f_frsize   = 1024
    s.f_blocks   = 1000000
    s.f_bfree    = 500000
    s.f_bavail   = 990000
    s.f_files    = 10000
    s.f_ffree    = 9900
    s.f_favail   = 9900
    s.f_fsid     = 23423
    s.f_flag     = 0
    s.f_namemax  = 10000

    s
  end

  def ioctl(ctx, path, cmd, arg, ffi, flags, data)
    # FT: I was not been able to test it.
    print "*** IOCTL: command: ", cmd, "\n"
  end

  def poll(ctx, path, ffi, ph, reventsp)
    print "*** POLL: ", path, "\n"
    # This is how we notify the caller if something happens:
    ph.notifyPoll();
    # when the GC harvests the object it calls fuse_pollhandle_destroy
    # by itself.
  end

  def init(ctx,rfuseconninfo)
    print "RFuse TestFS started\n"
    print "init called\n"
    print "proto_major:#{rfuseconninfo.proto_major}\n"
  end

end #class Fuse
