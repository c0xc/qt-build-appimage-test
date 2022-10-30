#!/bin/bash

if [[ -z "$GITHUB_WORKSPACE" ]]; then
    echo "workspace directory missing" >&2
    exit 1
fi
cd "$GITHUB_WORKSPACE" || exit $?

echo "build pipeline - application build script..."
ls -l /src /build
#echo "QT: $QTDIR"
if [ -f "/etc/profile.d/qt.sh" ]; then
    echo "found Qt env script, sourcing it..."
    source /etc/profile.d/qt.sh
fi
echo "QTDIR: $QTDIR"
if ! which qmake >/dev/null 2>&1; then
    echo "qmake missing!" >&2
fi
which qmake || exit $?

if [ -n "$INPUT_RECIPE" ]; then
    source "$INPUT_RECIPE"
fi

linuxdeploy=linuxdeployqt-continuous-x86_64.AppImage # temporarily not working
linuxdeploy=linuxdeploy-x86_64.AppImage
if ! which $linuxdeploy >/dev/null 2>&1; then
    echo "getting deploy tool: $linuxdeploy"
    if [ -f "/var/tmp/$linuxdeploy" ]; then
        ln -s /var/tmp/$linuxdeploy /usr/local/bin/
    else
        # https://github.com/probonopd/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage
        (cd /usr/local/bin && wget https://github.com/probonopd/linuxdeployqt/releases/download/continuous/$linuxdeploy && chmod +x $linuxdeploy)
        # TODO both: ./linuxdeploy-x86_64.AppImage ./linuxdeploy-plugin-qt-x86_64.AppImage
    fi
fi
which $linuxdeploy

pro_file=$(find . -mindepth 1 -maxdepth 1 -name "*.pro")
#if ls *.pro >/dev/null 2>&1; then
if [ -n "$pro_file" ]; then
    echo "BUILD - QMAKE: $pro_file"

    # IDEA build_workspace_qmake.sh

    qmake || exit $?
    #qmake CONFIG+=release PREFIX=/usr || exit $?

    INSTALL_ROOT=./AppDir make install
    if [ -f "$icon_file" ]; then
        cp -v "$icon_file" AppDir/
    fi
    if [ -f "$desktop_file" ]; then
        cp -v "$desktop_file" AppDir/
    fi
    if [ -f "$font_file" ]; then
        cp -v "$font_file" AppDir/
    fi

    ls -lArth AppDir



fi

