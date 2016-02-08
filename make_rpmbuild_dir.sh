#!/bin/bash

# This script will create a new Brooklyn build area

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR="/tmp/brooklyn-buildroot"
NAME="apache-brooklyn"
BROOKLYN_VERSION="0.8.0"
PACKAGE_VERSION="1"

# Change ~/.rpmmacros topdir value
/usr/bin/echo "%_topdir %(echo ${TOP_DIR})/rpmbuild" > ${HOME}/.rpmmacros

# Create rpmbuild directory structure
/usr/bin/mkdir -p\
    ${TOP_DIR}/rpmbuild/BUILD\
    ${TOP_DIR}/rpmbuild/BUILDROOT\
    ${TOP_DIR}/rpmbuild/RPMS\
    ${TOP_DIR}/rpmbuild/SOURCES\
    ${TOP_DIR}/rpmbuild/SPECS\
    ${TOP_DIR}/rpmbuild/SRPMS

# Additional directory structure
/usr/bin/mkdir -p\
    ${TOP_DIR}/rpmbuild/BUILDROOT/${NAME}-${BROOKLYN_VERSION}-${PACKAGE_VERSION}.x86_64/etc/brooklyn\
    ${TOP_DIR}/rpmbuild/BUILDROOT/${NAME}-${BROOKLYN_VERSION}-${PACKAGE_VERSION}.x86_64/etc/systemd/system\
    ${TOP_DIR}/rpmbuild/BUILDROOT/${NAME}-${BROOKLYN_VERSION}-${PACKAGE_VERSION}.x86_64/etc/var/run/brooklyn\
    ${TOP_DIR}/rpmbuild/BUILDROOT/${NAME}-${BROOKLYN_VERSION}-${PACKAGE_VERSION}.x86_64/opt/brooklyn\

# Copy tar.gz into ${TOP_DIR}/SOURCES directory
/usr/bin/cp ${SCRIPT_DIR}/tarball/*.tar.gz ${TOP_DIR}/rpmbuild/SOURCES/
/usr/bin/tar xf ${SCRIPT_DIR}/tarball/*.tar.gz -C ${TOP_DIR}/rpmbuild/BUILDROOT/${NAME}-${BROOKLYN_VERSION}-${PACKAGE_VERSION}.x86_64/opt/brooklyn/ --strip-components 1

# Copy files
/usr/bin/cp ${SCRIPT_DIR}/rpm/brooklyn.spec ${TOP_DIR}/rpmbuild/SPECS
/usr/bin/cp ${SCRIPT_DIR}/conf/brooklyn.conf ${TOP_DIR}/rpmbuild/BUILDROOT/${NAME}-${BROOKLYN_VERSION}-${PACKAGE_VERSION}.x86_64/etc/brooklyn/
/usr/bin/cp ${SCRIPT_DIR}/daemon/systemd/brooklyn.service ${TOP_DIR}/rpmbuild/BUILDROOT/${NAME}-${BROOKLYN_VERSION}-${PACKAGE_VERSION}._x86_64/etc/systemd/system/

# Run the build
/usr/bin/rpmbuild -ba ${TOP_DIR}/rpmbuild/SPECS/brooklyn.spec
