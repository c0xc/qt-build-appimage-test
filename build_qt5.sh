#!/bin/bash

# vim: tabstop=4 shiftwidth=4 softtabstop=4
# -*- sh-basic-offset: 4 -*-
#
# GITHUB BUILD PIPELINE - QT BUILD SCRIPT

# Pipeline build parameters
if [ -n "$INPUT_RECIPE" ]; then
    source "$INPUT_RECIPE"
fi

# This script will create a custom Qt build.
if [ -n "$NO_QT_BUILD" ]; then
    echo "Qt build disabled"
    exit
fi

# It will use the source tarball, if available: /var/tmp/qt*.tar.*
# In that case, the Qt version will be derived from the filename.
# If not found, the source tarball will be downloaded.
# In that case, the QT_VERSION variable will be used to determine what to get.
# qt-everywhere-src-5.15.2.tar.xz is 238M in size
# OpenSSL will also be (downloaded if missing and) built
# because it's required by Qt.
BUILD_BASE=/build
SRC=/src
QT_MAJOR="5"
QT_MINOR="15"
QT_BUG_FIX="2"
QT_VERSION="$QT_MAJOR.$QT_MINOR.$QT_BUG_FIX"
#DEBIAN_VERSION=$(lsb_release -cs)
MAKE_CORES="$(expr $(nproc) + 2)"

mkdir -p "$BUILD_BASE"
mkdir -p "$SRC"
cd "$BUILD_BASE"

function fetch_qt {
    local SRC_DIR="/src/qt-everywhere-src-$QT_VERSION"
    pushd /src

    if [ ! -d "$SRC_DIR" ]; then

        if [ ! -f "qt-everywhere-src-$QT_VERSION.tar.xz" ]; then
            wget -nv --no-check-certificate https://download.qt.io/archive/qt/$QT_MAJOR.$QT_MINOR/$QT_VERSION/single/qt-everywhere-src-$QT_VERSION.tar.xz || return $?
        fi

        if [ ! -f "md5sums.txt" ]; then
            wget -nv https://download.qt.io/archive/qt/$QT_MAJOR.$QT_MINOR/$QT_VERSION/single/md5sums.txt
        fi
        # --ignore-missing missing
        #md5sum -c md5sums.txt

        # Extract tarball
        tar xf qt-everywhere-src-$QT_VERSION.tar.xz
    fi
    popd
}

# Qt 5.15 DEPENDENCY: OPENSSL

if ! [ -d "/opt/openssl" ]; then
    # https://askubuntu.com/a/1127228
    cd /var/tmp
    if ! [ -f "openssl-1.1.1b.tar.gz" ]; then
        wget --no-check-certificate https://www.openssl.org/source/openssl-1.1.1b.tar.gz
    fi
    mkdir /opt/openssl
    cd /opt/openssl
    tar xfvz /var/tmp/openssl-1.1.1b.tar.gz --directory /opt/openssl
    export LD_LIBRARY_PATH=/opt/openssl/lib
    cd openssl-1.1.1b
    ./config --prefix=/opt/openssl --openssldir=/opt/openssl/ssl
    make && make install

fi

# QT: UNPACK TARBALL

cd $BUILD_BASE

VERSION=
SRC_FILE=
for i in /var/tmp/qt*.tar.*; do
    v=$(echo "$i" | grep -Po '5\.[0-9]+\.[0-9]+')
    if [ -z "$v" ]; then continue; fi
    VERSION=$v
    SRC_FILE=$i
done

if [ -z "$VERSION" ]; then
    echo "Qt not found, must download source tarball"
    #fetch_qt || exit $?
    fetch_qt
    VERSION=$QT_VERSION
    echo "Qt $VERSION downloaded:"
    ls -l "$SRC"
fi

datetime=$(date '+%F-%T')
BUILD_NAME="build-$VERSION"
if [ -d "$BUILD_NAME" ]; then
    exit
fi

if [ -n "$SRC_FILE" ]; then
    (cd $SRC && tar xf "$SRC_FILE")
fi

SRC_DIR="/src/qt-everywhere-src-$VERSION"
test -d "$SRC_DIR"

mkdir $BUILD_NAME
cd $BUILD_NAME || exit $?

# QT: BUILD

CONFIGURE_ARGS=()
CONFIGURE_ARGS+=("-nomake" "examples")
CONFIGURE_ARGS+=("-nomake" "tests")
CONFIGURE_ARGS+=("-nomake" "tools")
CONFIGURE_ARGS+=("-qt-libjpeg")
CONFIGURE_ARGS+=("-qt-libpng")
CONFIGURE_ARGS+=("-mng")
CONFIGURE_ARGS+=("-qt-zlib")
CONFIGURE_ARGS+=("-qt-harfbuzz")
CONFIGURE_ARGS+=("-qt-pcre")
CONFIGURE_ARGS+=("-ssl")
CONFIGURE_ARGS+=("-jasper")
#CONFIGURE_ARGS+=("-xcb" "-xcb-xlib" "-bundled-xcb-input")
CONFIGURE_ARGS+=("-qt-freetype")
CONFIGURE_ARGS+=("-qt-sqlite")
CONFIGURE_ARGS+=("-sql-mysql")
CONFIGURE_ARGS+=("-sql-psql")
CONFIGURE_ARGS+=("-sql-odbc")

# ERROR: Feature 'fontconfig' was enabled, but the pre-condition '!config.msvc && features.system-freetype && libs.fontconfig' failed.
# CONFIGURE_ARGS+=("-qt-freetype" "-fontconfig")
# remedy: put font in search path relative to executable or include one

if [ -d "/opt/openssl" ]; then
    CONFIGURE_ARGS+=("-I" "/opt/openssl/include")
    CONFIGURE_ARGS+=("-L" "/opt/openssl/lib")
fi

# Qt 5.15:
# ERROR: Unknown command line option '-qt-tiff'.
# ERROR: Unknown command line option '-qt-webp'.
# ERROR: Unknown command line option '-mng'.
# ERROR: Unknown command line option '-jasper'.

# ../../../../../../src/qt-everywhere-src-5.15.2/qtwebengine/src/3rdparty/chromium/third_party/webrtc/modules/desktop_capture/linux/screen_capturer_x11.h:101:3: error: 'XRRMonitorInfo' does not name a type
CONFIGURE_ARGS+=("-skip" "qtwebengine")

echo "# configure..."
echo \
    $SRC_DIR/configure \
    "${CONFIGURE_ARGS[@]}" >_CONFIGURE.log
$SRC_DIR/configure \
    -opensource -confirm-license \
    "${CONFIGURE_ARGS[@]}" \
    2>&1 | tee -a >_CONFIGURE.log
rc=$?
cat _CONFIGURE.log
if [ $rc -ne 0 ]; then
    echo "configure failed!" >&2
    tail -n 50 >_ERROR
    exit 1
fi

echo "# make..."
make -j"$MAKE_CORES" 2>&1 | tee >_MAKE.log
rc=$?
if [ $rc -ne 0 ]; then
    tail -n 50 >_ERROR
    exit 1
fi
tail -n 50 _MAKE.log
echo "make OK!"

# /src/qt-everywhere-src-5.15.2/qtimageformats/qtimageformats.pro
# make module-qtscript ?

cat <<EOF >/etc/profile.d/qt.sh
if [[ \$PATH != *qtbase* ]]; then
    QT5BASE=$PWD
    export QTDIR=\$QT5BASE/qtbase
    PATH=\$PATH:\$QTDIR/bin
    PATH=\$PATH:\$QT5BASE/qttools/bin
    export PATH
    export QMAKE=\$(which qmake)
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:\$QTDIR/lib
    #QT_PLUGIN_PATH=\$QTDIR/plugins
fi

EOF
cp -f /etc/profile.d/qt.sh /root/.bashrc
ls -l /etc/profile.d/qt.sh

# TODO either make install or symlink
# /usr/local/Qt-5.15.2/bin/lrelease
#root@1d337347363f:/tmp/CapacityTester# export QTDIR=/build/build-5.15.2/qtbase 
#root@1d337347363f:/tmp/CapacityTester# export LD_LIBRARY_PATH=$QTDIR/lib
#
# mkdir -p /usr/local/Qt-5.15.2/bin/
# ln -s /build/build-5.15.2/qttools/bin/lrelease /usr/local/Qt-5.15.2/bin/lrelease
make install

