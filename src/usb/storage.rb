class Usb::Storage

  def initialize(paths)
    fail if paths.count < 3

    @devs = paths.map do |path|
      Usb::Utils::FsHash.new(path, persistent: true)
    end
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
    @devs.count - 1
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

  def str2slices(str, size:)
    str.force_encoding('ASCII-8BIT').chars.each_slice(size).map(&:join)
  end

  def []=(key, data)
    size       = data.size
    slice_size = (size.to_f / striping_count).ceil

    parity = ''
    offset = 0
    slices = str2slices(data, size: slice_size)
    slice_sizes  = slices.map(&:bytesize)

    index = 0
    slices.each do |content|
      obj = {
        size:         size,
        index:        index,
        slice_sizes:  slice_sizes,
        content: content,
      }

      dev = @devs[index]
      dev[key] = pack(obj)
      parity ^= content

      index += 1
    end

    obj = {
      size:         size,
      index:        nil,
      slice_sizes:  slice_sizes,
      content:      parity,
    }
    dev = @devs[index]
    dev[key] = pack(obj)
  end

  def [](key)
    objs = @devs.map do |dev|
      str   = dev[key]
      slice = str ? unpack(str) : nil
    end

    fail_count = objs.count {|o| o.nil?} 

    return nil if fail_count == @devs.count
    fail       if fail_count >  1  

    sorted_objs = objs
      .select  {|o| o[:index]}
      .sort_by {|o| o[:index]}

    size = 0
    data = ''
    sorted_objs.each do |obj|
      size  = obj[:size   ]
      data += obj[:content]
    end

    data[0..size-1]
  end

end
