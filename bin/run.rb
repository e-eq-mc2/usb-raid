#!/usr/bin/ruby

require_relative '../src/usb'

root = Usb::Tree::Node.new("",0777)

RFuse.main(ARGV) { fs = Usb::Tree.new(root) }
