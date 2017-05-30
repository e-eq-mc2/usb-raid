#!/bin/sh

sudo umount /dev/fuse

bundle exec ruby ./bin/run.rb /path/to/the/mount/point
