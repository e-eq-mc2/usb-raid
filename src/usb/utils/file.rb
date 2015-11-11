module Usb::Utils::File
  class << self
    def size(path)
      File.size(path)
    end

    def mtime(path)
      File.mtime(path)
    end

    def max_path_size
      if Usb::Utils::Platform.windows?
        260 # Note: characters
      else
        1023 # Note: Byte
      end
    end

    def exceed_max_path_size?(path)
      if Usb::Utils::Platform.windows?
        path.length   > max_path_size
      else
        path.bytesize > max_path_size
      end
    end

    def readable?(path)
      if File.directory?(path) 
        File.readable?(path) 
      else
        begin
          File.open(path, 'rb') {|f| f.read(1)}
          true
        rescue => e
          Usb::Utils.log "#{self}.#{__method__} #{path} NOT READABLE(OPEN & READ) because of #{e.message} (#{e.class})"
          false
        end
      end
    end

    def locked?(path)
      return false if File.directory?(path)

      begin
        File.open(path, 'ab') { |f|
          f.flock(File::LOCK_SH)
        }
        return false
      rescue
        return true
      end
    end

    def support_acls?(path)
      if Usb::Utils::Platform.windows?
        File.supports_acls?(path)
      else
        true # Note: Is it ok?
      end
    end

    def permissions(path)
      return nil if not support_acls?(path)

      if Usb::Utils::Platform.windows?
        win32_permissions(path)
      else
        posix_permissions(path)
      end
    end

    def win32_permissions(path)
      win32_permissions_by_api(path)
    end

    def win32_permissions_by_api(path)
      fail if not Usb::Utils::Platform.windows?

      begin
        mode = {}
        File.get_permissions(path).each do |k,v| 
          mode[k] = File.securities(v)
          #mode[k] = v
        end
        mode
      rescue => e
        # Note: this exception comes about, If a user is deleted from OS and he/she is a member of acls of the path
        # No mapping between account names and security IDs was done. - LookupAccountSid (SystemCallError)
        Usb::Utils.log "#{self}.#{__method__} #{path} FAILED GET PERMISSIONS #{e.message} (#{e.class})"
        nil
      end
    end

    def win32_permissions_by_cmd(path)
      result = `icacls "#{path}"`

      acl_lines = result.split("\n")
      acl_lines.pop(2) #Note: Remvoe meaningless lines(empty line and status line)

      acl = []
      return acl if acl_lines.empty?

      acl << parse_first_acl_line(acl_lines.shift, path: path)

      acl_lines.each do |line|
        acl << parse_acl_line(line)
      end

      acl
    rescue => e
      # Note: this exception comes about, If a user is deleted from OS and he/she is a member of acls of the path
      # No mapping between account names and security IDs was done. - LookupAccountSid (SystemCallError)
      Usb::Utils.log "#{self}.#{__method__} #{path} FAILED GET PERMISSIONS #{e.message} (#{e.class})"
      nil
    end

    def parse_first_acl_line(line, path:)
      if line =~ /#{Regexp.escape(path)} (.*)/ #Note: Remove file path
        acl_line = $~[1]

        parse_acl_line(acl_line)
      else
        fail
      end
    end

    def parse_acl_line(line)
      if line =~ /(.*?):(.*)/
        account = $~[1].strip
        perms   = $~[2]

        {account => perms}
      else
        fail
      end
    end

    def posix_permissions(path)
      stat = File.stat(path)
      mode = stat.mode.to_s(8)
    end

    def stat(path)
      if Usb::Utils::Platform.windows?
        win32_stat(path)
      else
        posix_stat(path)
      end
    end

    def posix_stat(path)
      stat = File.stat(path)
      uid = stat.uid
      gid = stat.gid
      {
        type:  'posix',
        user:  uid2name(uid),
        group: gid2name(gid),
        user_info: {uid: uid},
        group_info: {gid: gid},
        acl:   stat.mode.to_s(8),
        mtime: Usb::Utils::Time.dump(stat.mtime),
      }
    end

    def win32_stat(path)
      owner = self.owner(path)
      group = self.group(path)
      {
        type:       'win32',
        user:       owner,
        group:      group,
        user_info:  account_info(owner),
        group_info: account_info(group),
        #acl:        win32_permissions(path),
        mtime:      Usb::Utils::Time.dump(File.mtime(path)),
        details:    {
          archive:       File.archive?(path)      ,
          blockdev:      File.blockdev?(path)     ,
          compressed:    File.compressed?(path)   ,
          encrypted:     File.encrypted?(path)    ,
          hidden:        File.hidden?(path)       ,
          indexed:       File.indexed?(path)      ,
          normal:        File.normal?(path)       ,
          offline:       File.offline?(path)      ,
          readonly:      File.readonly?(path)     ,
          reparse_point: File.reparse_point?(path),
          sparse:        File.sparse?(path)       ,
          system:        File.system?(path)       ,
          temporary:     File.temporary?(path)    ,
        }
      }
    end

    def owner(path)
      File.owner(path)
    rescue => e
      Usb::Utils.log_error "#{self}.#{__method__} #{path} #{e.message} (#{e.class})"
      nil
    end

    def group(path)
      File.group(path)
    rescue => e
      Usb::Utils.log_error "#{self}.#{__method__} #{path} #{e.message} (#{e.class})"
      nil
    end

    def uid2name(uid)
      Etc.getpwuid(uid).name
    end

    def gid2name(gid)
      Etc.getgrgid(gid).name
    end

    def account_info(username)
      return nil if username.nil?

      sid = Win32::Security::SID.new(username)
      {
        account:      sid.account,
        account_type: sid.account_type,
        domain:       sid.domain,
        host:         sid.host,
        sid:          sid.to_s
      }
    rescue => e
      Usb::Utils.log_error "#{self}.#{__method__} #{username} #{e.message} (#{e.class})"
      nil
    end

    def chmod(path, mode)
      if not support_acls?(path)
        Usb::Utils.log_error "#{self}.#{__method__} #{path}, #{mode} ACL NOT SUPPORTED"
        return nil
      end

      if Usb::Utils::Platform.windows? 
        File.set_permissions(path, mode)
      else
        File.chmod(mode, path)
      end
    end

    def reset_permissions(path)
      fail if not Usb::Utils::Platform.windows?

      res = `icacls "#{path}" /reset`

      if $?.success?
        nil
      else
        Usb::Utils.log_error "#{self}.#{__method__} #{path} #{$?} #{res}"
        fail #Note: for debug (It should be comment out)
      end
    end

    def mkdir_p(path)
      abspath     = Usb::Utils::Path.expand_path(path)
      descendants = Usb::Utils::Path.descendants(abspath)[1..-1] # Note: Exclude root(ex. C:/ and /)

      descendants.each do |pth|
        next if File.exist?(pth)

        FileUtils.mkdir(pth)

        yield pth if block_given?

      end
    end

    def read_each_line(path, mode: 'r')
      File.open(path, mode) do |file|
        #file.sync = true

        file.each_line do |line|
          check_encoding(line)
          yield line.chomp
        end
      end
    end

    def read_each_slice(path, n, mode: 'r')
      slice = []
      read_each_line(path) do |line|
        check_encoding(line)
        slice << line.chomp

        if slice.count >= n
          yield slice
          slice.clear
        end
      end

      yield slice if not slice.empty?
    end

    def readblock(path, offset:, size:)
      File.read(path, size, offset, {mode: 'rb'})
    rescue SystemCallError => e
      nil
    end

    def readpartial(path, maxlen)
      size  = 0
      File.open(path, 'rb') do |file|
        #file.sync = true

        file_size = file.size # Note: ERROR WITH JRUBY
        while data = Usb::Utils::Bmt.run("File#read") { file.read(maxlen) }
          size += data.bytesize

          log_read_progress(path, size, file_size, maxlen)
          yield data
          
          break if size >= file_size # Note: To avoid infinit loop when reading my log file
        end
      end

      size
    end

    def log_read_progress(path, read_size, file_size, read_unit)
      rate = "%.3f" % (read_size.to_f / file_size * 100)
      rs = read_size.human_size
      fs = file_size.human_size
      ru = read_unit.human_size
      Usb::Utils.log "READ #{rs} / #{fs} #{rate} % (#{ru}) #{path}"
    end

    def writepartial(path, chunks, before_write: nil)
      pth = before_write ? before_write.call(path) : path

      size = 0
      File.open(pth, 'wb') do |file|
        chunks.each do |chunk|
          data = yield chunk
          file.write data
          size += data.bytesize
        end
      end
      size
    end

    def atomic_writepartial(path, chunks, before_write: nil, &block)
      do_atomic_writepartial(path, chunks, before_write: before_write, &block)
    end

    def check_encoding(str)
      fail if not str.utf8?
    end

    def generate_uniq_path(path, prefix:)
      return path if not File.exist?(path)

      dirname  = File.dirname(path)
      filename = File.basename(path, '.*')
      ext      = File.extname(path)

      trycount = 1
      begin
        renamed_path = File.join(dirname, "#{prefix}#{trycount}.#{filename}#{ext}")
        trycount += 1
      end while File.exist?(renamed_path)

      Usb::Utils.log "#{self}.#{__method__} #{path} #{prefix} -> #{renamed_path}"

      renamed_path
    end

    def identical?(dir0, dir1)
      do_identical?(dir0, dir1) && do_identical?(dir1, dir0)
    end

    def random_basenme
      [
        Thread.current.object_id,
        Process.pid,
        SecureRandom.random_number(1 << 32)
      ].join('.')
    end

    def zip_r(path, outfile)
      FileUtils.rm_f outfile

      pth = File.dirname(path)
      Zip::File.open(outfile, 'w') do |zipfile|
        Dir["#{path}/**/**"].reject {|f| f == outfile }.each do |f|
          rel = f.sub(File.join(pth, ''), '')
          zipfile.add(rel, f)
        end
      end
    end

    private
    def do_atomic_writepartial(path, chunks, before_write: nil)
      tempfile = Tempfile.new(File.basename(path))
      tempfile.binmode

      size = 0
      chunks.each do |chunk|
        data = yield chunk, size
        tempfile.write data 
        size += data.bytesize
      end
      tempfile.close

      pth = before_write ? before_write.call(path) : path # Note: Rename if exists
      Usb::Utils.log "#{self}.#{__method__} #{pth}: #{pth.length} chars, #{pth.bytesize} Byte > #{max_path_size}" if exceed_max_path_size?(pth)

      # Note: Errno::ENOENT may be thrown when path exceed max path
      FileUtils.mv(tempfile.path, pth)

      [size, pth]
    end

    # Note: Active Support
    def do_atomic_writepartial_as(path, chunks, before_write: nil)
      pth = before_write ? before_write.call(path) : path # Note: Rename if exists

      size = 0
      File.atomic_write(pth) do |file|
        #file.sync = true

        chunks.each do |chunk|
          data = yield chunk, size
          file.write data
          size += data.bytesize
        end

      end
      [size, pth]
    end

    def do_identical?(dir0, dir1)
      if not FileTest.directory?(dir0)
        puts "Not found #{dir0} (dir0)"
        return false
      end

      Find.find(dir0).each do |path0| 
        tail = Usb::Utils::Path.drop_head(path0, dir0)
        path1 = File.join(dir1, tail)

        if FileTest.directory?(path0)
          if not FileTest.directory?(path1)
            puts "Not found the directory #{path1}"
            return false 
          end
        else
          if not FileTest.file?(path1)
            puts "Not found the file #{path1}"
            return false 
          end

          if not FileUtils.compare_file(path0, path1)
            puts "#{path0} != #{path1}"
            return false 
          end
        end
      end

      true
    end

  end
end
