#!/usr/bin/ruby

require_relative '../src/usb'

data_paths = [
  '/path/to/the/mount/point',l
  'data1',
  'data0',
]

Usb::Tree::Commit.json_path = 'repo.json' 
Usb::Tree.setup_storage(data_paths)

commit = Usb::Tree::Commit.load_HEAD || Usb::Tree::Commit.reset

puts ARGV
RFuse.main(ARGV) { fs = Usb::Tree.new(commit) }
