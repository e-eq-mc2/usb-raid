class Usb::Storage

  def initialize(paths)
    fail if paths.count < 3

    @storages = paths.map do |path|
      Usb::Utils::FsHash.new(path, persistent: true)
    end
  end

  def config_path(root)
    File.join(root, config.yml)
  end

  def config_path(root)
    File.join(root, 'config.yml')
  end

  def load_config(root)
    Usb::Utils::Config.load( config_path(root) )
  end

  def initialized?(root)
    ! load_config(root).nil?
  end

  def striping_count
    @storages.count - 1
  end

  def format
    :marshal
  end

  def pack(data)
    Usb::Utils::Serializer.pack(data, format: format)
  end

  def unpack(str)
    Usb::Utils::Serializer.unpack(str, format: format)
  end

  def compute_parity(chunks)
    chunks.reduce('') do |parity, chunk|
      parity ^= chunk
    end
  end

  def str2chunks(str, size:)
    str.force_encoding('ASCII-8BIT').chars.each_slice(size).map(&:join)
  end

  def []=(key, data)
    size       = data.size
    chunk_size = (size.to_f / striping_count).ceil

    chunks = str2chunks(data, size: chunk_size)
    chunks << compute_parity(chunks)
    chunk_sizes = chunks.map(&:bytesize)

    chunks.each.with_index do |content,index|
      obj = {
        size:         size,
        index:        index,
        chunk_sizes:  chunk_sizes,
        content:      content,
      }

      storage = @storages[index] || fail
 
      begin
        storage[key] = pack(obj)
      rescue => e
        raise Errno::EIO.new
      end
    end
  end

  def [](key)
    objs = @storages.map do |storage|
      str = storage[key]
      str ? unpack(str) : nil
    end

    failure_count = objs.count {|o| o.nil?} 

    raise Errno::EIO.new if failure_count >  1  

    objs << repaire(objs) if failure_count == 1

    sorted_objs = objs.compact.sort_by {|o| o[:index]}

    sorted_objs.pop

    content = sorted_objs.reduce('') {|c,o| c + o[:content]}
    content
  end

  def repaire(objs)
    index2obj   = {}
    size        = nil
    chunk_sizes = nil
    objs.each do |obj|
      next if obj.nil?
      index       = obj[:index      ]
      size        = obj[:size       ]
      chunk_sizes = obj[:chunk_sizes]

      index2obj[index] = obj
    end

    missing_index = nil
    missing_size  = nil
    chunk_sizes.each_with_index do |csz,idx|
      next if not index2obj[idx].nil?
      missing_index = idx
      missing_size  = csz
    end

    missing_content = ''
    index2obj.values.each do |obj|
      missing_content ^= obj[:content]
    end

    {
      size:        size,
      chunk_sizes: chunk_sizes,
      index:       missing_index,
      content:     missing_content[0..(missing_size - 1)]
    }
  end

end
