#!/bin/bash

# vim: tabstop=4 shiftwidth=4 softtabstop=4
# -*- sh-basic-offset: 4 -*-
#
# GITHUB BUILD PIPELINE - OS PREPARATION

# Pipeline build parameters are unavailable here
echo "BUILD PIPELINE - OS PREPARATION..."
echo "OS: $OS_NAME:$OS_RELEASE"

OS_ID=$(cat /etc/os-release | grep ^ID | cut -f2 -d'=')
echo "$OS_ID"

#if [ -n "$INPUT_RECIPE" ]; then
#    source "$INPUT_RECIPE"
#fi
# TODO THIS IS EMPTY!!!
#

#if [ -n "$NO_QT_BUILD" ]; then
echo "PREP TEST:"
env
echo "INSTALL_DEBIAN = $INSTALL_DEBIAN"
echo "PREP TEST..."
exit

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

