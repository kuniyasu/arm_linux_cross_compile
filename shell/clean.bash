#!/bin/bash

for a in build bin lib lib64 libexec build include etc share sbin var arm-unknown-linux-gnueabihf; do
  if [ -d $a ]; then
    rm -rf $a
  fi
done
