class Usb::Tree::Root < Usb::Tree::Node

  class << self
    def load_HEAD
      digest = read('HEAD')

      do_load(digest) if digest
    end
  end

  def update(path)
    chain = path2chain(path, with_name: true)

    leaf, leaf_name = chain.first

    yield leaf, leaf_name

    update_chain(chain)
  end

  def insert(child, path)
    parent_path = File.dirname(path)

    update(parent_path) do |parent, parent_name|
      raise Errno::EISDIR.new(path) if not parent.dir?

      ## SAVE NEW OBJECT ##
      child.save
      #####################

      child_name = File.basename(path)
      parent.insert_child(child, child_name)
    end
  end

  def remove(path)
    parent_path = File.dirname(path)

    update(parent_path) do |parent, parent_name|
      raise Errno::EISDIR.new(path) if not parent.dir?

      child_name = File.basename(path)
      parent.remove_child(child_name)
    end
  end

  def write(path, data:, offset:)
    length = 0
    update(path) do |leaf, leaf_name|
      raise Errno::EISDIR.new(path) if not leaf.file?

      length = leaf.write(data: data, offset: offset)
    end

    length
  end

  def truncate(path, length:)
    update(path) do |leaf, leaf_name|
      raise Errno::EISDIR.new(path) if not leaf.file?

      leaf.truncate(length)
    end
  end

  def read(path, offset: 0, size:)
    obj = search(path)
    raise Errno::EISDIR.new(path) if not obj.file?

    obj.read(offset: offset, size: size)
  end

  def search(path)
    path2chain(path).first
  end

  def update_chain(chain)
    child, child_name = chain.first

    chain.drop(1).each do |parent, parent_name|
      parent.insert_child(child, child_name)
      child      = parent
      child_name = parent_name
    end

    update_HEAD
  end

  def update_HEAD
    self.class.write('HEAD', digest)
  end

  def path2chain(path, with_name: false)
    chain = []

    obj  = self
    name = nil
    chain << ( with_name ? [obj, name] : obj )

    Usb::Utils::Path.each_name(path) do |name|
      obj = obj.read_child(name)
      raise Errno::ENOENT.new(name) if obj.nil?

      chain << ( with_name ? [obj, name] : obj )
    end

    chain.reverse
  end

end
