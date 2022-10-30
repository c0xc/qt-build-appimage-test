FROM debian/eol:jessie

RUN \
    printf "deb [check-valid-until=no] http://archive.debian.org/debian jessie-backports main contrib non-free" >/etc/apt/sources.list.d/backports.list && \
    printf "deb http://deb.debian.org/debian/ stretch main contrib non-free" >/etc/apt/sources.list.d/stretch.list && \
    echo "" >/etc/apt/preferences.d/backports && \
    printf "Package: *\nPin: release a=jessie-backports\nPin-Priority: 650\n\n" >>/etc/apt/preferences.d/backports && \
    printf "Package: *\nPin: release a=stretch\nPin-Priority: 100\n\n" >>/etc/apt/preferences.d/backports && \
    printf "Package: *\nPin: origin deb.debian.org\nPin-Priority: 100\n\n" >>/etc/apt/preferences.d/backports

RUN \
    sed -i 's/main$/main contrib non-free/g' /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y \
    flex bison gperf libicu-dev libxslt-dev ruby \
    libxcursor-dev libxcomposite-dev libxdamage-dev libxrandr-dev libxtst-dev libxss-dev libdbus-1-dev libevent-dev libfontconfig1-dev libcap-dev libpulse-dev libudev-dev libpci-dev libnss3-dev libasound2-dev libegl1-mesa-dev gperf bison nodejs \
    wget libclang-dev vim

ENTRYPOINT ["/entrypoint.sh"]
