#!/bin/bash

if [[ -z "$GITHUB_WORKSPACE" ]]; then
    echo "workspace directory missing" >&2
    exit 1
fi
cd "$GITHUB_WORKSPACE" || exit $?

echo "build pipeline - application build script..."
echo "QT: $QTDIR"
if [ -x "/etc/profile.d/qt.sh" ]; then
    echo "# found Qt env script, sourcing it..."
    source /etc/profile.d/qt.sh
fi
which qmake
which qmake || exit $?

if [ -n "$INPUT_RECIPE" ]; then
    source "$INPUT_RECIPE"
fi

linuxdeployqt=linuxdeployqt-continuous-x86_64.AppImage
if ! which $linuxdeployqt >/dev/null 2>&1; then
    # https://github.com/probonopd/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage
    (cd /usr/local/bin && wget https://github.com/probonopd/linuxdeployqt/releases/download/continuous/$linuxdeployqt && chmod +x $linuxdeployqt)
fi

pro_file=$(find . -mindepth 1 -maxdepth 1 -name "*.pro")
#if ls *.pro >/dev/null 2>&1; then
if [ -n "$pro_file" ]; then

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

