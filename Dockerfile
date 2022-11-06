ARG os_name
ARG os_release
FROM ${os_name}:${os_release}
RUN echo "arg1? os_name = ${os_name}"
RUN echo "arg1? OS_RELEASE = ${OS_RELEASE}/${os_release}"
ARG OS_NAME
ENV OS_NAME $OS_NAME
ARG OS_RELEASE
ENV OS_RELEASE $OS_RELEASE
RUN echo "arg2? os_name = ${os_name}"
RUN echo "arg2? OS_RELEASE = ${OS_RELEASE}/${os_release}"

# Get build args for preparation script
ARG no_qt_build
ENV no_qt_build $no_qt_build
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
RUN /var/tmp/build_qt5.sh
ENTRYPOINT ["/var/tmp/build_src.sh"]
