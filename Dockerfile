# Import base OS as defined in workflow (or Debian 8)
# uses: c0xc/github-build-qt-appimage-action@master
# with:
#   os_name: fedora
#   os_release: 31
ARG os_name
ARG os_release
FROM ${os_name}:${os_release}
# Re-import args/vars because they are blank after FROM statement
ARG os_name
ENV os_name $os_name
ARG os_release
ENV os_release $os_release

# Get build args for preparation script
ARG no_qt_build
ENV no_qt_build $no_qt_build
ARG QT_VERSION
ENV QT_VERSION $QT_VERSION
ARG APT_INSTALL
ENV APT_INSTALL $APT_INSTALL
ARG YUM_INSTALL
ENV YUM_INSTALL $YUM_INSTALL

# Prepare OS by installing build dependencies
COPY prepare_os.sh /var/tmp/
RUN /var/tmp/prepare_os.sh

# Run build scripts
# Qt tarball is copied first (optional)
# If missing, it will be downloaded when building Qt
COPY build*.sh qt-everywhere-src-*.tar.* *.AppImage /var/tmp/
RUN /var/tmp/build_qt5.sh

# Arguments, application build script
ENV workspace $workspace
ENTRYPOINT ["/var/tmp/build_src.sh"]
