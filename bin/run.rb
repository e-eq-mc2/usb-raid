#!/usr/bin/ruby

require_relative '../src/usb'

data_paths = [
  '/media/n-nishizawa/a0aed6ed-7cb1-434d-8cf7-f7783666cb8d',
  #'data2',
  'data1',
  'data0',
]

Usb::Tree::Commit.json_path = 'repo.json' 
Usb::Tree.setup_storage(data_paths)

commit = Usb::Tree::Commit.load_HEAD || Usb::Tree::Commit.reset

puts ARGV
RFuse.main(ARGV) { fs = Usb::Tree.new(commit) }
