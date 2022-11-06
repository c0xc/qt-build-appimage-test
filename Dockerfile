#RUN echo "00test00 I'm building for target $TARGETPLATFORM on: p=$BUILDPLATFORM o=$BUILDOS a=$BUILDARCH v=$BUILDVARIANT"
FROM debian/eol:jessie
ARG OS_NAME
ARG os_name
ARG OS_RELEASE
ARG os_release
ENV OS_NAME $OS_NAME
ENV os_name $os_name
RUN echo "arg? OS_NAME = ${OS_NAME}"
RUN echo "arg? os_name = ${os_name}"
RUN echo "arg? OS_RELEASE = ${OS_RELEASE}/${os_release}"
ARG TARGETPLATFORM
ARG TARGETARCH
ARG TARGETOS
ARG BUILDOS
ARG BUILDARCH
ARG BUILDVARIANT
ARG BUILDPLATFORM
RUN echo "I'm building for target $TARGETPLATFORM on: p=$BUILDPLATFORM o=$BUILDOS a=$BUILDARCH v=$BUILDVARIANT"
ENV TARGETPLATFORM $TARGETPLATFORM
ENV TARGETARCH $TARGETARCH
RUN echo "I'm buildinggg ? tp=$TARGETPLATFORM ta=$TARGETARCH"
RUN pwd; ls -la
# FROM debian/eol:jessie (default)
#ARG OS_NAME=debian/eol
ARG OS_NAME
#ARG OS_RELEASE=jessie
ARG OS_RELEASE
FROM ${OS_NAME}:${OS_RELEASE}
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

RUN false

# Qt tarball is copied first (optional)
# If missing, it will be downloaded
COPY prepare_os.sh qt-everywhere-src-*.tar.* /var/tmp/
RUN /var/tmp/prepare_os.sh

# Run build scripts
COPY build*.sh qt-everywhere-src-*.tar.* *.AppImage /var/tmp/
ENTRYPOINT ["/var/tmp/build_src.sh"]
