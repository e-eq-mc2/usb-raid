class Commit
  include Usb::Tree::Base

  class << self
    attr_accessor :json_path

    def type
      'commit'
    end

    def load_HEAD
      digest = read('HEAD')

      do_load(digest)
    rescue => e
      nil
    end

    def reset
      root = Usb::Tree::Root.new(mode: 0777, uid: 0, gid: 0)
      root.save

      commit = new(root: root.to_meta, parent: nil)
      root.commit = commit

      commit
    end

    def write_json(data)
      File.open(json_path, 'w') do |file|
        file.write data.to_json
      end
    end

  end

  def initialize(root:, parent:, created_at: nil, type: nil)
    @root       = root
    @parent     = parent
    @created_at = created_at || Time.now

    save

    fail if type && type != self.type
  end

  def root
    Usb::Tree::Root.do_load(@root[:digest]) 
  end

  def parent
    @parent ? self.class.load(@parent) : nil
  end

  def load_commits
    commits = [self]
    loop {
      commit = commits.last.parent

      break if commit.nil?
      commits << commit
    }

    commits
  end

  def update_HEAD
    self.class.write_json(all_dump_json)
    self.class.write('HEAD', digest)
  end

  def each(&block)
    load_commits.each &block
  end

  def to_core
    {
      type:       type,
      root:       @root,
      parent:     @parent,
      created_at: @created_at,
    }
  end

  def size
    @root[:size]
  end

  def to_meta
    {
      type:   type,
      size:   size,
      digest: digest
    }
  end

  def dump_json
    {
      type:       type,
      root:       root.dump_json(name: '/'),
      parent:     @parent,
      created_at: @created_at,
      size:       size,
    }
  end

  def all_dump_json
    load_commits.map {|c| c.dump_json}
  end

end
