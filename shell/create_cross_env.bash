#!/bin/bash

TARGET=arm-unknown-linux-gnueabihf
MAKE_OPT=-j8

BINUTILS_VER=2.25
GCC_VER=5.2.0
LINUX_VER=4.1.6
GLIBC_VER=2.20

BINUTILS_NAME=binutils-$BINUTILS_VER
GCC_NAME=gcc-$GCC_VER
LINUX_NAME=linux-$LINUX_VER
GLIBC_NAME=glibc-$GLIBC_VER

SYSROOT=$PWD
PREFIX=$SYSROOT

PATH=$PREFIX/bin:$PATH
LD_LIBRARY_PATH=$PREFIX/lib64:$PREFIX/lib:$LD_LIBRARY_PATH

function download_file(){
    if [ ! -f $2 ]; then
      wget $1/$2
    fi
}

function download_files(){
  if [ ! -d download ]; then
    mkdir download
  fi
  pushd download

    download_file http://ftp.gnu.org/gnu/binutils/ $BINUTILS_NAME.tar.gz
    download_file http://ftp.gnu.org/gnu/gcc/$GCC_NAME $GCC_NAME.tar.gz
    download_file https://www.kernel.org/pub/linux/kernel/v4.x/ $LINUX_NAME.tar.gz
    download_file http://ftp.gnu.org/gnu/glibc/ $GLIBC_NAME.tar.gz

  popd

}

function install_binutils(){
  if [ ! -d build ]; then
    mkdir build
  fi

  if [ ! -d build/build-$BINUTILS_NAME ]; then
    mkdir build/build-$BINUTILS_NAME
  fi

  cd build
    tar zxf ../download/$BINUTILS_NAME.tar.gz

    cd build-$BINUTILS_NAME
      ../$BINUTILS_NAME/configure \
      --prefix=$PREFIX --target=$TARGET \
      --disable-multilib

      make $MAKE_OPT

      make install
    cd ..
  cd ..

  pushd $TARGET
    if [ ! -d usr ]; then
      mkdir usr

      mv bin lib usr

      ln -s usr/bin bin
      ln -s usr/lib lib
      ln -s usr/include include
    fi

  popd
}

function install_bootstrap(){
  if [ ! -d build ]; then
    mkdir build
  fi

  if [ ! -d build/build0-$GCC_NAME ]; then
    mkdir build/build0-$GCC_NAME
  fi

  cd build

    tar zxf ../download/$GCC_NAME.tar.gz

    cd $GCC_NAME
      ./contrib/download_prerequisites
    cd ..

    cd build0-$GCC_NAME

      ../$GCC_NAME/configure --prefix=$PREFIX --target=$TARGET \
      --disable-threads \
      --disable-shared \
      --enable-__cxa_atexit \
      --disable-libmudflap \
      --disable-libgomp \
      --disable-nls \
      --disable-libstdcxx \
      --disable-libatomic \
      --disable-libquadmath \
      --disable-decimal-float \
      --disable-libitm \
      --disable-libsanitizer \
      --disable-libcilkrts \
      --disable-cloog \
      --disable-libssp \
      --without-headers \
      --enable-languages=c \
      --disable-multilib

      make $MAKE_OPT all-gcc
      make $MAKE_OPT all-target-libgcc

      make install-gcc
      make install-target-libgcc

    cd ..

  cd ..
}

download_files
install_binutils
install_bootstrap
