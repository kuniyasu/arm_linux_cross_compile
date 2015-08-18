#!/bin/bash

for a in build bin lib lib64 include etc share arm-unknown-linux-gnueabihf; do
  if [ -d $a ]; then
    rm -rf $a
  fi
done
