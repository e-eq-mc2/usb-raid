class Usb::Utils::FsHash 
  DIR_DEPTH    = 2
  DIRNAME_SIZE = 2

  class << self
    attr_accessor :debug

    def log(msg)
      Usb::Utils.log msg if debug
    end

    def clean(path)
      log "CLEAN: #{path}"
      FileUtils.remove_entry_secure(path)
    end

    def pack(data)
      Usb::Utils::Serializer.pack(data, format: :marshal)
    end

    def unpack(str)
      Usb::Utils::Serializer.unpack(str, format: :marshal)
    end
  end

  def self.auto_clean_proc(path)
    pid = $$
    proc {
      if pid == $$
        if path && ! path.empty? && File.directory?(path) && ! File.symlink?(path)
          clean(path)
          log "CLEAN PID: #{$$}, PATH: #{path}"
        else
          log "SKIP pid: #{$$}, path: #{path}, directory?: #{File.directory?(path)}, symlink?: #{File.symlink?(path)}"
        end
      end
    }
  end

  attr_reader :root, :persistent, :created_at

  def initialize(root = nil, persistent: false)
    self.class.debug = true
    setup(root, persistent: persistent)
  end

  def setup(root = nil, persistent:)
    @created_at = Time.now
    @root       = root || Dir.mktmpdir
    @persistent = persistent
    ObjectSpace.define_finalizer(self, self.class.auto_clean_proc(@root.dup)) if not persistent
    self
  end

  def clear
    self.class.clean(root)
    setup(@root, persistent: @persistent)
  end

  def [](key)
    puts "key= #{key}"
    path = key2path(key)
    read(path)
  end

  def []=(key, val)
    puts "key= #{key}"
    path = key2path(key)
    write(path, val)
  end

  def delete(key)
    data = [key]

    path = key2path(key)
    remove(path)

    data
  rescue Errno::ENOENT => e
    self.class.log(e.message)
    nil
  end

  def remove(path)
    FileUtils.rm(path)
  end

  def key?(key)
    path = key2path(key)
    File.exist? path
  end

  def read(path)
    str = File.open(path, 'rb') do |f|
      f.read
    end
    self.class.log "READ: #{path} size: #{str.bytesize} Byte"

    self.class.unpack(str)
  rescue Errno::ENOENT => e
    self.class.log "NOT FOUND #{path} (#{e.message})".red
    nil
  end

  def write(path, data)
    dir = File.dirname(path)
    FileUtils.mkdir_p(dir)

    str = self.class.pack(data)
    File.open(path, 'wb') do |f|
      f.write str
    end
    self.class.log "WRITE: #{path} size: #{str.bytesize} Byte"
  end
 
  def key2path(key)
    leftover = path_key(key)
    fail if leftover.size < DIRNAME_SIZE * DIR_DEPTH + 1

    dirs = []
    DIR_DEPTH.times do 
      dirs << leftover[0, DIRNAME_SIZE]
      leftover = leftover[DIRNAME_SIZE..-1]
    end

    File.join(root, *dirs, leftover)
  end

  def path_key(key)
    Usb::Utils::Digest.sha1(key.to_s)
  end
 
end


