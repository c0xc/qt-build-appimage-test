#!/bin/bash

if [[ -z "$GITHUB_WORKSPACE" ]]; then
    echo "workspace directory missing" >&2
    exit 1
fi
cd "$GITHUB_WORKSPACE" || exit $?

# Build parameters
if [ -n "$INPUT_RECIPE" ]; then
    source "$INPUT_RECIPE"
fi

# Load Qt
echo "build pipeline - application build script..."
ls -l /src /build
if [ -f "/etc/profile.d/qt.sh" ]; then
    echo "found Qt env script, sourcing it..."
    cat /etc/profile.d/qt.sh
    source /etc/profile.d/qt.sh
fi
echo "QTDIR: $QTDIR"
if ! which qmake >/dev/null 2>&1; then
    echo "qmake missing!" >&2
fi
which qmake || exit $?

# Prepare linuxdeploy tool for creating AppImage
linuxdeploy=linuxdeploy-x86_64.AppImage
if ! which $linuxdeploy >/dev/null 2>&1; then
    # TODO download current version if vars[DOWNLOAD_LINUXDEPLOY] ...
    echo "getting deploy tool: $linuxdeploy"
    if [ -f "/var/tmp/$linuxdeploy" ]; then
        ln -s /var/tmp/$linuxdeploy /usr/local/bin/
    else
        # TODO fetch both: ./linuxdeploy-x86_64.AppImage ./linuxdeploy-plugin-qt-x86_64.AppImage
        (cd /usr/local/bin && wget https://github.com/linuxdeploy/linuxdeploy/releases/download/1-alpha-20220822-1/$linuxdeploy && chmod +x $linuxdeploy)
        (cd /usr/local/bin && wget https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage && chmod +x linuxdeploy-plugin-qt-x86_64.AppImage)
        # https://github.com/linuxdeploy/linuxdeploy/releases/download/1-alpha-20220822-1/linuxdeploy-x86_64.AppImage
        # https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage
    fi
fi
which $linuxdeploy

# Build application
pro_file=$(find . -mindepth 1 -maxdepth 1 -name "*.pro")
if [ -n "$pro_file" ]; then
    # qmake
    echo "BUILD - QMAKE: $pro_file"

    # IDEA build_workspace_qmake.sh

    qmake || exit $?
    #qmake CONFIG+=release PREFIX=/usr || exit $?

    mkdir -p ./AppDir
    INSTALL_ROOT=./AppDir make install || exit $?
    # https://docs.appimage.org/
    if [ -f "$icon_file" ]; then
        cp -v "$icon_file" AppDir/
    fi
    if [ -f "$desktop_file" ]; then
        cp -v "$desktop_file" AppDir/
    fi
    if [ -f "$font_file" ]; then
        cp -v "$font_file" AppDir/
    fi

    echo "$pro_file done; bin/:"
    ls -lArth bin
    echo "AppDir/:"
    ls -lArthR AppDir

else
    echo "NO BUILD FILE FOUND"
    exit 1
fi

# Run linuxdeploy tool to create AppImage
if (which $linuxdeploy && ls AppDir) >/dev/null 2>&1; then

    # Copy Qt plugins, if requested
    if [ -n "$ADD_QT_PLUGINS" ]; then
        mkdir -p AppDir/usr/bin/
        cp -var $QTDIR/plugins/platforms/ AppDir/usr/bin/
    fi
    # Copy font file
    if [ -n "$font_file" ]; then
        mkdir -p AppDir/usr/lib/fonts
        cp -v "$font_file" AppDir/usr/lib/fonts/
    elif [ -n "$ADD_FONTS" ]; then
        mkdir -p AppDir/usr/lib/fonts
        cp -v res/*.ttf AppDir/usr/lib/fonts/
    fi

    # 

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

