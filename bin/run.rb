#!/usr/bin/ruby

require_relative '../src/usb'

Usb::Tree::Node.data_path = 'data/node'
Usb::Tree::Blob.data_path = 'data/blob'

root = Usb::Tree::Node.load_HEAD || Usb::Tree::Node.new(name: "", mode: 0777)

RFuse.main(ARGV) { fs = Usb::Tree.new(root) }
