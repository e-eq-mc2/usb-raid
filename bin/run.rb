#!/usr/bin/ruby

require_relative '../src/usb'

data_paths = [
  'data0',
  'data1',
  'data2',
]

Usb::Tree::Node.setup_storage(data_paths)
Usb::Tree::Blob.setup_storage(data_paths)

root = Usb::Tree::Node.load_HEAD || Usb::Tree::Node.new(name: "", mode: 0777)

RFuse.main(ARGV) { fs = Usb::Tree.new(root) }
