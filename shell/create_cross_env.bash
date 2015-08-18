#!/bin/bash

TARGET=arm-unknown-linux-gnueabihf
MAKE_OPT=-j8
LINUX_DEFCONFIG=socfpga_defconfig

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
LD_LIBRARY_PATH=$PREFIX/lib64:$PREFIX/lib:$PREFIX/$TARGET/lib:$LD_LIBRARY_PATH

FP_OPT="--with-fp --with-float=hard --with-fpu=neon-vfpv4 --with-mode=thumb --with-arch=armv7-a "

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
      --with-sysroot=$PREFIX/$TARGET


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
      ln -s usr/sbin sbin

    fi

  popd
}

function install_bootstrap_gcc(){
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
      --disable-multilib \
      --with-fp \
      --with-float=hard \
      --with-fpu=neon-vfpv4 \
      --with-mode=thumb \
      --with-arch=armv7-a


      make $MAKE_OPT all-gcc
      make $MAKE_OPT all-target-libgcc

      make install-gcc
      make install-target-libgcc

    cd ..

  cd ..
}

install_bootstrap_linux(){
  if [ ! -d build ]; then
    mkdir build
  fi

  cd build

    tar zxf ../download/$LINUX_NAME.tar.gz

    mv $LINUX_NAME build0-$LINUX_NAME

    cd build0-$LINUX_NAME
      make mrproper

      make ARCH=arm $LINUX_DEFCONFIG
      make ARCH=arm headers_check

      make ARCH=arm \
      INSTALL_HDR_PATH=$PREFIX/$TARGET/usr \
      headers_install \

    cd ..
  cd ..
}

install_bootstrap_glibc(){
  if [ ! -d build ]; then
    mkdir build
  fi

  if [ ! -d build/build0-$GLIBC_NAME ]; then
    mkdir build/build0-$GLIBC_NAME
  fi

  cd build
    if [ -d $GLIBC_NAME ]; then
      rm -rf $GLIBC_NAME
    fi

    tar zxf ../download/$GLIBC_NAME.tar.gz

    cd build0-$GLIBC_NAME

      CC=$TARGET-gcc \
      CXX=$TARGET-g++ \
      RANLIB=$TARGET-ranlib \
      AS=$TARGET-as \
      ../$GLIBC_NAME/configure \
      --build=$MACHTYPE \
      --host=$TARGET \
      --target=$TARGET \
      libc_cv_forced_unwind=yes \
      libc_cv_c_cleanup=yes \
      --prefix=/usr \
      --with-headers=$PREFIX/$TARGET/usr/include \
      --disable-multilib \
      --with-fp \
      --with-float=hard \
      --with-fpu=neon-vfpv4 \
      --with-mode=thumb \
      --with-arch=armv7-a \
      --disable-sjlj-exceptions \
      --enable-threads=posix \
      --disable-nscd \
      --config-cache

      make $MAKE_OPT
      make install install_root=$PREFIX/$TARGET
    cd ..
  cd ..

  if [ -d $PREFIX/$TARGET/usr/sys-include ]; then
    rm -rf $PREFIX/$TARGET/sys-include
  fi

}

install_gcc_build1(){
  if [ ! -d build ]; then
    mkdir build
  fi

  cd build

  if [ -d $GCC_NAME ]; then
    rm -rf $GCC_NAME
  fi

  tar zxf ../download/$GCC_NAME.tar.gz

  cd $GCC_NAME
    ./contrib/download_prerequisites
  cd ..

  if [ -d build1-$GCC_NAME ]; then
    rm -rf build1-$GCC_NAME
  fi

  mkdir build1-$GCC_NAME

    cd build1-$GCC_NAME

      ../$GCC_NAME/configure --prefix=$PREFIX --target=$TARGET \
      --with-headers=$PREFIX/$TARGET/usr/include \
      --enable-languages=c \
      --disable-multilib \
      --with-fp \
      --with-float=hard \
      --with-fpu=neon-vfpv4 \
      --with-mode=thumb \
      --with-arch=armv7-a

      make $MAKE_OPT
      make install

    cd ..
  cd ..

  if [ -d $PREFIX/$TARGET/sys-include ]; then
    rm -rf $PREFIX/$TARGET/sys-include
  fi

}

install_linux_kernel_header(){
  if [ ! -d build ]; then
    mkdir build
  fi

  cd build

  if [ -d build1-$LINUX_NAME ]; then
    rm -rf build1-$LINUX_NAME
  fi

  tar zxf ../download/$LINUX_NAME.tar.gz

  mv $LINUX_NAME build1-$LINUX_NAME

  cd build1-$LINUX_NAME
    make mrproper
    make ARCH=arm $LINUX_DEFCONFIG
    make ARCH=arm headers_check
    make ARCH=arm INSTALL_HDR_PATH=$PREFIX headers_install
  cd ..

  cd ..
}

install_glibc(){
  if [ ! -d build ]; then
    mkdir build
  fi

  cd build

  if [ -d $GLIBC_NAME ]; then
    rm -rf $GLIBC_NAME
  fi

  tar zxf ../download/$GLIBC_NAME.tar.gz

  if [ -d build1-$GLIBC_NAME ]; then
    rm -rf build1-$GLIBC_NAME
  fi

  mkdir build1-$GLIBC_NAME

  cd build1-$GLIBC_NAME

    CC=$TARGET-gcc \
    CXX=$TARGET-g++ \
    LD=$TARGET-gcc \
    AS=$TARGET-as \
    RANLIB=$TARGET-ranlib \
    ../$GLIBC_NAME/configure \
    libc_cv_forced_unwind=yes \
    libc_cv_c_cleanup=yes \
    --disable-werror \
    --build=x86_64-unknown-linux-gnu \
    --host=$TARGET \
    --target=$TARGET \
    --prefix=/ \
    --disable-multilib \
    --with-headers=$PREFIX/include \
    --with-fp \
    --with-float=hard \
    --with-fpu=neon-vfpv4 \
    --with-mode=thumb \
    --with-arch=armv7-a \
    --disable-sjlj-exceptions \
    --enable-threads=posix \
    --disable-nscd \
    --config-cache

    make $MAKE_OPT
    make install install_root=$SYSROOT
  cd ..
  cd ..

  if [ -d $PREFIX/$TARGET/sys-include ]; then
    rm -rf $PREFIX/$TARGET/sys-include
  fi
}

install_gcc_build2(){
  if [ ! -d build ]; then
    mkdir build
  fi

  cd build

  if [ -d $GCC_NAME ]; then
    rm -rf $GCC_NAME
  fi

  tar zxf ../download/$GCC_NAME.tar.gz

  cd $GCC_NAME
    ./contrib/download_prerequisites
  cd ..

  if [ -d build2-$GCC_NAME ]; then
    rm -rf build2-$GCC_NAME
  fi

  mkdir build2-$GCC_NAME

  cd build2-$GCC_NAME

  ../$GCC_NAME/configure --prefix=$PREFIX --target=$TARGET \
  --with-headers=$PREFIX/include \
  --disable-multilib \
  --with-fp \
  --with-float=hard \
  --with-fpu=neon-vfpv4 \
  --with-mode=thumb \
  --with-arch=armv7-a

  make $MAKE_OPT
  make install

  cd ..
  cd ..
}

install_libstdcxx(){
  if [ ! -d build ]; then
    mkdir build
  fi

  cd build

  if [ -d $GCC_NAME ]; then
    rm -rf $GCC_NAME
  fi

  tar zxf ../download/$GCC_NAME.tar.gz
  cd $GCC_NAME
    ./contrib/download_prerequisites
  cd ..

  if [ -d build_libstdxx-$GCC_NAME ]; then
    rm -rf build_libstdxx-$GCC_NAME
  fi

  mkdir build_libstdxx-$GCC_NAME

  cd build_libstdxx-$GCC_NAME

  CC=$TARGET-gcc \
  CXX=$TARGET-g++ \
  LD=$TARGET-gcc \
  AS=$TARGET-as \
  RANLIB=$TARGET-ranlib \
  ../$GCC_NAME/libstdc++-v3/configure --prefix=$PREFIX --host=$TARGET \
  --with-gxx-include-dir=$PREFIX/include/c++/$GCC_VER \
  --disable-multilib \
  --disable-libstdcxx-pch

  make
  make install
  cd ..
  cd ..
}

download_files
install_binutils

install_bootstrap_gcc
install_bootstrap_linux
install_bootstrap_glibc

install_gcc_build1

install_linux_kernel_header
install_glibc
install_gcc_build2

install_libstdcxx
