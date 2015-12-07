require 'rfuse'
require 'pry'

class Usb::Tree
end

require_relative 'tree/base'
require_relative 'tree/node'
require_relative 'tree/root'
require_relative 'tree/commit'
require_relative 'tree/blob'

class Usb::Tree
  class << self
    attr_reader :storage

    def setup_storage(paths)
      @storage = Usb::Storage.new(paths)
    end
  end

  def initialize(commit)
    @commit = commit
    @commit.update_HEAD

    @root   = commit.root
  end

  def log(str)
    puts str
  end

  def update_commit
    @commit = Usb::Tree::Commit.new(
      root:   @root.to_meta, 
      parent: @commit ? @commit.to_meta : nil
    )

    @commit.save

    #@commit.all_dump
    @commit.update_HEAD
  end

  def dump_all(path)
    @commit.dump_all if File.basename(path) == 'dump'
  end

  # The new readdir way, c+p-ed from getdir
  def readdir(ctx, path, filler, offset, ffi)
    log "#{__method__} path: #{path}"

    obj = @root.search(path)

    raise Errno::ENOTDIR.new(path) if not obj.dir?

    obj.read_each_child do |name, obj|
      filler.push(name, obj.stat, 0)
    end
  end

  def getattr(ctx, path)
    log "#{__method__} path: #{path}"

    obj = @root.search(path)
    obj.stat
  end

  def mkdir(ctx, path, mode)
    log "#{__method__} path: #{path}".red

    obj = Node.new(mode: mode, uid: ctx.uid, gid: ctx.gid)
    res = @root.insert(obj, path)

    update_commit

    res
  end

  def mknod(ctx,path,mode,major,minor)
    log "#{__method__} path: #{path}".red
    
    dump_all(path)

    obj = Blob.new(mode: mode, uid: ctx.uid, gid: ctx.gid)
    res = @root.insert(obj, path)

    update_commit

    res
  end

  def open(ctx,path,ffi)
    log "#{__method__} path: #{path}"
  end

  def release(ctx, path, ffi)
    log "#{__method__} path: #{path}"
  end

  def flush(ctx, path, ffi)
    log "#{__method__} path: #{path}".red
  end

  def chmod(ctx, path, mode)
    log "#{__method__} path: #{path}".red
  end

  def chown(ctx,path,uid,gid)
    log "#{__method__} path: #{path}".red
  end

  def truncate(ctx, path, length)
    log "#{__method__} path: #{path}".red

    res = @root.truncate(path, length: length)

    update_commit

    res
  end

  def utime(ctx, path, actime, modtime)
    log "#{__method__} path: #{path}".red
  end

  def unlink(ctx, path)
    log "#{__method__} path: #{path}".red

    @root.remove(path)
  end

  def rmdir(ctx, path)
    log "#{__method__} path: #{path}".red

    @root.remove(path)
  end

  def symlink(ctx, path, as)
    log "#{__method__} path: #{path}".red
  end

  def rename(ctx, from_path, to_path)
    log "#{__method__} from_path: #{from_path} to_path: #{to_path}".red

    obj = @root.search(from_path)

    @root.remove(from_path)
    res = @root.insert(obj, to_path)

    update_commit

    res
  end

  def link(ctx, path, as)
    log "#{__method__} path: #{path}".red
  end

  def read(ctx, path, size, offset, ffi)
    log "#{__method__} path: #{path}"

    @root.read(path, offset: offset, size: size)
  end

  def write(ctx, path, data, offset, ffi)
    log "#{__method__} path: #{path}".red

    res = @root.write(path, data: data, offset: offset)

    update_commit

    res
  end

  def setxattr(ctx, path, name, data, flags)
    log "#{__method__} path: #{path}".red

    @root.setxattr(path, name: name, data: data, flags: flags)
  end

  def getxattr(ctx, path, name)
    log "#{__method__} path: #{path}"

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

  def listxattr(ctx, path)
    log "#{__method__} path: #{path}"

    obj = @root.search(path)
    value = obj.listxattr
  end

  def removexattr(ctx, path, name)
    log "#{__method__} path: #{path}".red

    obj = @root.search(path)
    obj.removexattr(name)
  end

  def opendir(ctx, path, ffi)
    log "#{__method__} path: #{path}"
  end

  def releasedir(ctx, path, ffi)
    log "#{__method__} path: #{path}"
  end

  def fsyncdir(ctx, path, meta, ffi)
    log "#{__method__} path: #{path}".red
  end

  # Some random numbers to show with df command
  def statfs(ctx, path)
    stat = RFuse::StatVfs.new()
    stat.f_bsize    = 1024
    stat.f_frsize   = 1024
    stat.f_blocks   = 1000000
    stat.f_bfree    = 500000
    stat.f_bavail   = 990000
    stat.f_files    = 10000
    stat.f_ffree    = 9900
    stat.f_favail   = 9900
    stat.f_fsid     = 23423
    stat.f_flag     = 0
    stat.f_namemax  = 10000

    stat
  end

  def ioctl(ctx, path, cmd, arg, ffi, flags, data)
    # FT: I was not been able to test it.
    log "#{__method__} path: #{path}".yellow
  end

  def poll(ctx, path, ffi, ph, reventsp)
    log "#{__method__} path: #{path}".yellow

    # This is how we notify the caller if something happens:
    ph.notifyPoll();
    # when the GC harvests the object it calls fuse_pollhandle_destroy
    # by itself.
  end

  def init(ctx,rfuseconninfo)
    log "RFuse started"
    log "init called"
    log "proto_major: #{rfuseconninfo.proto_major}"
  end

end #class Fuse
