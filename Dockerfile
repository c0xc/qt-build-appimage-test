# FROM debian/eol:jessie (default)
ARG OS_NAME=debian/eol
ARG OS_RELEASE=jessie
FROM $OS_NAME:$OS_RELEASE
ARG OS_NAME
ENV OS_NAME $OS_NAME
ARG OS_RELEASE
ENV OS_RELEASE $OS_RELEASE

# Get build args for preparation script
ARG NO_QT_BUILD
ENV NO_QT_BUILD $NO_QT_BUILD
ARG QT_VERSION
ENV QT_VERSION $QT_VERSION
ARG APT_INSTALL
ENV APT_INSTALL $APT_INSTALL
ARG YUM_INSTALL
ENV YUM_INSTALL $YUM_INSTALL

# Qt tarball is copied first (optional)
# If missing, it will be downloaded
COPY prepare_os.sh qt-everywhere-src-*.tar.* /var/tmp/
RUN /var/tmp/prepare_os.sh

# Run build scripts
COPY build*.sh qt-everywhere-src-*.tar.* *.AppImage /var/tmp/
ENTRYPOINT ["/var/tmp/build_src.sh"]
