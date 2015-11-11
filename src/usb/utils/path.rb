module Usb::Utils::Path
  class << self
    def acceptable_filesystem_encoding?
      # Note: 
      # With Ruby 1.9, Dir.entries returns UTF-8 NFD on Mac OS X.
      # But UTF-8 NFC is used in others(script, sdtin and so on).
      # And in Ruby 2.x, Dir.entries returns UTF-8 NFC on Mac OS X.
      valid_encoding = false

      Dir.mktmpdir do |tmpdir|
        fname = 'だ'.encode(Encoding::UTF_8) # Note: It becomes UTF-8 NFC on Ruby 1.9, 2.x on Mac OS X
        path  = File.join(tmpdir, fname)
        File.open(path, 'wb') do |file|
          file.write  Time.now
        end

        Dir.entries(tmpdir, encoding: Encoding::UTF_8).each do |entry|
          if entry == fname
            valid_encoding = true 
            break
          end
        end
      end

      valid_encoding
    end

    def root?(path)
      Pathname.new(path).root?
    end

    def absolute?(path)
      if Usb::Utils::Platform.windows?
        Pathname.new(path).absolute? && include_drive?(path)
      else
        Pathname.new(path).absolute?
      end
    end

    def include_drive?(path)
      path =~ windows_drive_regexp
    end

    def no_backslash?(path)
      not path.include?('\\')
    end

    def same?(a, b)
      expand_path(a) == expand_path(b)
    end

    def contain?(child:, parent:)
      # Note: Without separator at the end of child and parent, the case below matches
      # child: /a/b.x, parent:/a/b
      #
      # -> with separator, they doesn't match
      #
      # child: /a/b.x/, parent: /a/b/
      son = File.join(expand_path(child ), '')
      dad = File.join(expand_path(parent), '')

      # Note: the string(dad) in regexp must be escaped
      # Ex.
      # son = '/a/b (x86)/c', dad = '/a/b (x86)/'
      # In this case, '(' , ')' in dad is interpreted as metacharacters, so dad doesn't match son.
      if son =~ /\A#{Regexp.escape(dad)}/
        true
      else
        false
      end
    end

    def independent?(paths)
      # Note: Array#combination doesn't run its block, if Array#count == 1
      paths.combination(2) do |a,b|
        return false if contain?(child: a, parent: b)
        return false if contain?(child: b, parent: a)
      end
      true
    end

    def clean_path(path)
      Pathname.new(path).cleanpath.to_s
    end

    def expand_path(path)
      Pathname.new(path).expand_path.cleanpath.to_s
    end

    def uniq_basenames?(paths)
      basenames = paths.map {|pth| File.basename(expand_path(pth))}

      basenames.count == basenames.uniq.count
    end

    def group_by_root(paths)
      paths.group_by {|path| root(path)}
    end

    def root(path)
      if expand_path(path) =~ /\A.*?\// # Note: ? means lazy matching
        $~[0]
      else
        fail
      end
    end

    def descendants(path)
      des = []
      Pathname.new(path).descend {|pth| des << pth.to_s}
      des
    end

    def common_path(paths)
      # Note: 
      # Ex. paths = ['/a/b/x', '/a/b/c/x/n', '/a/b/y']
      # -> '/a/b'
      # Ex. paths  = ['/a/b/x']
      # -> '/a/b/x'

      des_by_path = paths.map {|pth| descendants(pth)}
      refdes      = des_by_path.min_by {|des| des.count}
      # Note:
      # Ex. paths = ['/a/b/c', '/a/b/n/x', '/a/b/m/y/0']
      # des_by_path = [ # array of each path's descendants
      #   ['/a', '/a/b', '/a/b/c'              ],
      #   ['/a', '/a/b', '/a/b/n', '/a/b/n/x'  ],
      #   ['/a', '/a/b', '/a/b/m', '/a/b/m/y/0']
      # ]
      # refdes =['/a', '/a/b', '/a/b/c'] # matching reference
      longest = nil
      refdes.each_with_index do |ref, i|
        break if not des_by_path.all? {|des| des[i] == ref}

        longest = ref
      end
      longest
    end

    def common_dirname(paths)
      # Note: 
      # Ex. paths = ['/a/b/x', '/a/b/c/x/n', '/a/b/y']
      # -> '/a/b'
      # Ex. paths  = ['/a/b/x']
      # -> '/a/b'
      if paths.count == 1
        File.dirname(paths.first)
      else
        common(paths)
      end
    end

    def drive(path)
      if path =~ windows_drive_regexp
        $~[0]
      else
        nil
      end
    end

    def drive_letter(path)
      if path =~ windows_drive_regexp
        $~[1]
      else
        nil
      end
    end

    def drop_drive(path)
      path.sub(windows_drive_regexp, '')
    end

    def drop_head(path, head)
      pth = File.join(path, '')
      hd  = File.join(head, '')
      if pth =~ /\A#{Regexp.escape(hd)}(.*)/
        $~[1].sub(/#{File::SEPARATOR}\Z/, '')
      else
        path
      end
    end

    def reject_if_parent(paths)
      # Note:
      # paths = ['/a/b/c', '/a/b/c/d', '/a/b/x'] 
      # => '/a/b/c' is a parent of '/a/b/c/d', so it will be rejected.
      # ['/a/b/c/d', '/a/b/x']
      paths.select do |a|
        paths.none? do |b|
          # Note: 
          # If a has any children(b), a is a parent of them.
          # So such a must be removed == only paths that has no child must be selected.
          a != b && contain?(parent: a, child: b) 
        end
      end
    end

    def reject_if_child(paths)
      # Note:
      # paths = ['/a/b/c', '/a/b/c/d', '/a/b/x'] 
      # => '/a/b/c/d' is a child of '/a/b/c', so it will be rejected.
      # ['/a/b/c', '/a/b/x']
      paths.select do |a|
        paths.none? do |b|
          # Note: 
          # If a has any parents(b), a is a child of them.
          # So such a must be removed == only paths that has no parent must be selected.
          a != b && contain?(child: a, parent: b) 
        end
      end
    end

    def parent_of(path, suspects:)
      suspects.each do |suspect|
        return suspect if contain?(child: path, parent: suspect)
      end
      nil
    end

    def child_of(path, suspects:)
      suspects.each do |suspect|
        return suspect if contain?(child: suspect, parent: path)
      end
      nil
    end

    def parent?(path, suspects:)
      !! child_of(path, suspects: suspects)
    end

    private
    def windows_drive_regexp
      /\A([a-zA-Z]):/
    end
  end
end
