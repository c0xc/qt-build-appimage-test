#!/bin/bash
#
# vim: tabstop=4 shiftwidth=4 softtabstop=4
# -*- sh-basic-offset: 4 -*-
#
# GITHUB BUILD PIPELINE - APPLICATION BUILD SCRIPT

if [[ -z "$GITHUB_WORKSPACE" ]]; then
    echo "workspace directory missing" >&2
    exit 1
fi
cd "$GITHUB_WORKSPACE" || exit $?

# Pipeline build parameters
if [ -n "$INPUT_RECIPE" ]; then
    source "$INPUT_RECIPE"
fi

# Load Qt (custom Qt build if available, standard Qt installation otherwise)
echo "BUILD PIPELINE - APPLICATION BUILD SCRIPT..."
ls -l /src /build
if [ -f "/etc/profile.d/qt.sh" ]; then
    echo "found Qt env script, sourcing it..."
    cat /etc/profile.d/qt.sh
    source /etc/profile.d/qt.sh
fi
if [ -n "$QTDIR" ]; then
    echo "QTDIR: $QTDIR"
else
    echo "QTDIR not defined, using Qt installation from distribution" >&2
fi
if ! which qmake >/dev/null 2>&1; then
    echo "qmake missing!" >&2
fi
echo -n "= "
which qmake || exit $?
echo

# Prepare linuxdeploy tool for creating AppImage
# It should be included in the Docker container, but if not, download it...
linuxdeploy=linuxdeploy-x86_64.AppImage
if ! which $linuxdeploy >/dev/null 2>&1; then
    # TODO download current version if vars[DOWNLOAD_LINUXDEPLOY] ...
    # Copy (from Docker image) or (try to) download linuxdeploy tool
    echo "getting deploy tool: $linuxdeploy"
    if [ -f "/var/tmp/$linuxdeploy" ]; then
        (cd /usr/local/bin && cp -v /var/tmp/$linuxdeploy . && chmod +x $linuxdeploy)
    else
        # https://github.com/linuxdeploy/linuxdeploy/releases/download/1-alpha-20220822-1/linuxdeploy-x86_64.AppImage
        # https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage
        (cd /usr/local/bin && wget -nv https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/$linuxdeploy && chmod +x $linuxdeploy)
    fi
    # linuxdeploy Qt plugin
    if [ -x "/usr/local/bin/linuxdeploy-plugin-qt-x86_64.AppImage" ]; then
        :
    elif [ -f "/var/tmp/linuxdeploy-plugin-qt-x86_64.AppImage" ]; then
        (cd /usr/local/bin && cp -v /var/tmp/linuxdeploy-plugin-qt-x86_64.AppImage . && chmod +x linuxdeploy-plugin-qt-x86_64.AppImage)
    else
        # https://github.com/linuxdeploy/linuxdeploy/releases/download/1-alpha-20220822-1/linuxdeploy-x86_64.AppImage
        # https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage
        (cd /usr/local/bin && wget -nv https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage && chmod +x linuxdeploy-plugin-qt-x86_64.AppImage)
    fi
fi
echo -n "= "
which $linuxdeploy
echo

# Install other system dependencies
apt_packages=
if [ -n "$INSTALL_DEBIAN" ]; then
    apt_packages=$INSTALL_DEBIAN
elif [ -n "$PREP_APT_INSTALL" ]; then
    apt_packages=$PREP_APT_INSTALL
fi
if [ -n "$apt_packages" ]; then
    echo "installing Debian packages: $INSTALL_DEBIAN"
    apt-get install -y $INSTALL_DEBIAN || exit $?
fi
echo

# Build application and copy it to AppDir/
pro_file=$(find . -mindepth 1 -maxdepth 1 -name "*.pro")
if [ -n "$pro_file" ]; then
    # qmake
    echo "BUILD - QMAKE: $pro_file"

    qmake || exit $?
    #qmake CONFIG+=release PREFIX=/usr || exit $?

    mkdir -p ./AppDir
    INSTALL_ROOT=./AppDir make install || exit $?
    # https://docs.appimage.org/
    if [ -f "$icon_file" ]; then
        cp -vf "$icon_file" AppDir/
    fi
    if [ -f "$desktop_file" ]; then
        cp -vf "$desktop_file" AppDir/
    fi
    if [ -f "$font_file" ]; then
        cp -vf "$font_file" AppDir/
    fi

    echo "$pro_file done; bin/:"
    ls -lArth bin
    echo "AppDir/:"
    ls -lArthR AppDir

else
    echo "NO BUILD FILE FOUND"
    exit 1
fi

# Add Qt plugins to be included in bundle - if using manual Qt build
# Without these plugins, the application may fail to start!
if [[ -n "$QTDIR" ]]; then
    cp -var "$QTDIR/plugins/platforms/" AppDir/usr/bin/
fi

# Run linuxdeploy tool to create AppImage
if (which $linuxdeploy && ls AppDir) >/dev/null 2>&1; then

    # Copy font file
    if [ -n "$font_file" ]; then
        mkdir -p AppDir/usr/lib/fonts
        cp -v "$font_file" AppDir/usr/lib/fonts/
    elif [ -n "$ADD_FONTS" ]; then
        mkdir -p AppDir/usr/lib/fonts
        cp -v res/*.ttf AppDir/usr/lib/fonts/
    fi

    # Arguments
    args=()
    if [ -z "$bin_file" ]; then
        bin_file="bin/*"
    fi
    args+=("--executable" $bin_file)
    if [ -n "$desktop_file" ]; then
        desktop_file_name=$(basename "$desktop_file")
        if [ -f "AppDir/$desktop_file_name" ]; then
            args+=("--desktop-file" "AppDir/$desktop_file_name")
        else
            args+=("--desktop-file" $desktop_file)
        fi
    fi
    if [ -n "$icon_file" ]; then
        icon_file_name=$(basename "$icon_file")
        if [ -f "AppDir/$icon_file_name" ]; then
            args+=("--icon-file" "AppDir/$icon_file_name")
        else
            args+=("--icon-file" $icon_file)
        fi
    fi
    # Arguments, continued
    args+=("--appdir" "AppDir")
    args+=("--output" "appimage")
    echo "linuxdeploy arguments: ${args[@]}"
    $linuxdeploy "${args[@]}"

fi

