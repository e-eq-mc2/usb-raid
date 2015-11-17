#!/bin/sh

sudo umount /dev/fuse

rm -rf /media/n-nishizawa/644ac99c-e821-4cb0-8236-bf42fcde68cf/*
rm -rf /media/n-nishizawa/a0aed6ed-7cb1-434d-8cf7-f7783666cb8d/*
rm -rf data0

bundle exec ruby ./bin/run.rb /media/n-nishizawa/NEKO_STORAGE
