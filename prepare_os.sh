#!/bin/bash

# vim: tabstop=4 shiftwidth=4 softtabstop=4
# -*- sh-basic-offset: 4 -*-
#
# GITHUB BUILD PIPELINE - PREPARE SCRIPT

# Pipeline build parameters
if [ -n "$INPUT_RECIPE" ]; then
    source "$INPUT_RECIPE"
fi

echo "PREP TEST:"
env
echo "INSTALL_DEBIAN = $INSTALL_DEBIAN"

# Install other system dependencies
if [ -n "$INSTALL_DEBIAN" ]; then
    echo "installing Debian packages: $INSTALL_DEBIAN"
    apt-get install -y $INSTALL_DEBIAN || exit $?
fi
echo

