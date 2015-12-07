#!/bin/sh

sudo umount /dev/fuse

rm -rf /media/n-nishizawa/a0aed6ed-7cb1-434d-8cf7-f7783666cb8d/*
rm -rf data0
rm -rf data1
rm -rf data2

bundle exec ruby ./bin/run.rb /media/n-nishizawa/NEKO_STORAGE
