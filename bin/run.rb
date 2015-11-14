#!/usr/bin/ruby

require_relative '../src/usb'

data_paths = [
  'data0',
  'data1',
  'data2',
]

Usb::Tree.setup_storage(data_paths)

root = Usb::Tree::Root.load_HEAD || Usb::Tree::Root.new(mode: 0777)

puts ARGV
RFuse.main(ARGV) { fs = Usb::Tree.new(root) }
