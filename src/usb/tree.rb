require 'rfuse'
require 'pry'

class Usb::Tree
end

require_relative 'tree/base'
require_relative 'tree/node'
require_relative 'tree/blob'

class Usb::Tree
  def initialize(root)
    @root = root
  end

  # The new readdir way, c+p-ed from getdir
  def readdir(ctx, path, filler, offset, ffi)
    node = @root.search(path)

    raise Errno::ENOTDIR.new(path) if node.file?

    node.each do |name, obj|
      filler.push(name, obj.stat, 0)
    end
  end

  def getattr(ctx, path)
    obj = @root.search(path)
    obj.stat
  end #getattr

  def mkdir(ctx, path, mode)
    name = File.basename(path)
    node = Node.new(name: name, mode: mode)

    parent = @root.insert(node, path)

    parent
  end #mkdir

  def mknod(ctx,path,mode,major,minor)
    name = File.basename(path)
    blob = Blob.new(name: name, mode: mode, uid: ctx.uid, gid: ctx.gid)

    @root.insert(blob, path)
  end #mknod

  def open(ctx,path,ffi)
  end

  #def release(ctx,path,fi)
  #end

  #def flush(ctx,path,fi)
  #end

  def chmod(ctx,path,mode)
    d=@root.search(path)
    d.mode=mode
  end

  def chown(ctx,path,uid,gid)
    d=@root.search(path)
    d.uid=uid
    d.gid=gid
  end

  def truncate(ctx, path, last)
    @root.truncate(path, last: last)
  end

  def utime(ctx,path,actime,modtime)
    d=@root.search(path)
    d.actime=actime
    d.modtime=modtime
  end

  def unlink(ctx,path)
    @root.remove_obj(path)
  end

  def rmdir(ctx,path)
    @root.remove_obj(path)
  end

  #def symlink(ctx,path,as)
  #end

  def rename(ctx,path,as)
    d = @root.search(path)
    @root.remove_obj(path)
    @root.insert(d,path)
  end

  #def link(ctx,path,as)
  #end

  def read(ctx,path,size,offset,fi)
    @root.read(path, offset: offset, size: size)
  end

  def write(ctx, path, data, offset, fi)
    @root.write(path, data: data, offset: offset)
  end

  def setxattr(ctx,path,name,value,size,flags)
    d=@root.search(path)
    d.setxattr(name,value,flags)
  end

  def getxattr(ctx,path,name)
    d=@root.search(path)
    if (d)
      value=d.getxattr(name)
      if (!value)
        value=""
        #raise Errno::ENOENT.new #TODO raise the correct error :
        #NOATTR which is not implemented in Linux/glibc
      end
    else
      raise Errno::ENOENT.new
    end
    return value
  end

  def listxattr(ctx,path)
    d=@root.search(path)
    value= d.listxattr()
    return value
  end

  def removexattr(ctx,path,name)
    d=@root.search(path)
    d.removexattr(name)
  end

  #def opendir(ctx,path,ffi)
  #end

  #def releasedir(ctx,path,ffi)
  #end

  #def fsyncdir(ctx,path,meta,ffi)
  #end

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
    return s
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
