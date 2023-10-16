#!/bin/bash

echo "ENV CENTREON_PLUGINS_VERSION = ${CENTREON_PLUGINS_VERSION}"

CENTREON_PLUGINS_VERSION="20231017"

# curl -LO https://github.com/centreon/centreon-plugins/archive/refs/tags/${CENTREON_PLUGINS_VERSION}.tar.gz
curl -LO https://github.com/handfreezer/z_centreon-plugins/archive/refs/tags/${CENTREON_PLUGINS_VERSION}.tar.gz

tar xzvf ${CENTREON_PLUGINS_VERSION}.tar.gz
ln -sf *centreon-plugins-${CENTREON_PLUGINS_VERSION}/src src
