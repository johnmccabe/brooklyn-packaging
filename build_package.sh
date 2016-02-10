#!/bin/bash -x

set -eu
set -o pipefail

# Check args number
if [ "$#" -ne 2 ]; then
    echo "Usage: $(basename ${0}) <package_type> <package_release_version>"
    exit 1
fi

NAME="apache-brooklyn"
TOP_DIR="/tmp/brooklyn-buildroot"

PACKAGE_TYPE=${1}
PACKAGE_VERSION=${2}
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if tarball exists in tarball/ dir
if [ ! -f ${SCRIPT_DIR}/tarball/apache-brooklyn*.tar.gz ]; then
    echo "Brooklyn tar.gz file not found in ${SCRIPT_DIR}/tarball"
    exit 1
fi

# Check if there is only single tarball inside tarball/ dir
if [ $(ls -al "${SCRIPT_DIR}/tarball" | grep apache-brooklyn*.tar.gz | wc -l) -gt "1" ]; then
    echo "Too many tar.gz files found in ${SCRIPT_DIR}, exiting..."
    exit 1
else
    # Set the brooklyn version
    BROOKLYN_VERSION=$(basename $(ls ${SCRIPT_DIR}/tarball/apache-brooklyn*.tar.gz) | grep -oe "[0-9]\.[0-9]\.[0-9]")
fi

# Change ~/.rpmmacros topdir value
echo "%_topdir %(echo ${TOP_DIR})/rpmbuild" > ${HOME}/.rpmmacros

# Clean ${TOP_DIR}
rm -rf ${TOP_DIR}

# Create rpmbuild directory structure
mkdir -p\
    ${TOP_DIR}/rpmbuild/BUILD\
    ${TOP_DIR}/rpmbuild/BUILDROOT\
    ${TOP_DIR}/rpmbuild/RPMS\
    ${TOP_DIR}/rpmbuild/SOURCES\
    ${TOP_DIR}/rpmbuild/SPECS\
    ${TOP_DIR}/rpmbuild/SRPMS

# Additional directory structure
mkdir -p\
    ${TOP_DIR}/rpmbuild/BUILDROOT/${NAME}-${BROOKLYN_VERSION}-${PACKAGE_VERSION}.x86_64/etc/brooklyn\
    ${TOP_DIR}/rpmbuild/BUILDROOT/${NAME}-${BROOKLYN_VERSION}-${PACKAGE_VERSION}.x86_64/etc/systemd/system\
    ${TOP_DIR}/rpmbuild/BUILDROOT/${NAME}-${BROOKLYN_VERSION}-${PACKAGE_VERSION}.x86_64/var/log/brooklyn\
    ${TOP_DIR}/rpmbuild/BUILDROOT/${NAME}-${BROOKLYN_VERSION}-${PACKAGE_VERSION}.x86_64/opt/brooklyn\

# Unpack tarball into BUILDROOT directory
if [ -f ${SCRIPT_DIR}/tarball/apache-brooklyn*.tar.gz ]; then
    tar xf ${SCRIPT_DIR}/tarball/apache-brooklyn*.tar.gz -C ${TOP_DIR}/rpmbuild/BUILDROOT/${NAME}-${BROOKLYN_VERSION}-${PACKAGE_VERSION}.x86_64/opt/brooklyn/ --strip-components 1
else
    echo "Brooklyn tar.gz file not found in ${SCRIPT_DIR}/tarball"
    exit 1
fi

# Add Brooklyn version and Release version to spec file
sed -i.bkp "s|^Version:.*|Version:\t${BROOKLYN_VERSION}|" "${SCRIPT_DIR}/spec/brooklyn.spec"
sed -i.bkp "s|^Release:.*|Release:\t${PACKAGE_VERSION}|" "${SCRIPT_DIR}/spec/brooklyn.spec"

#TODO Grab changelog data and append to the spec file

# Copy files
cp ${SCRIPT_DIR}/conf/brooklyn.conf ${TOP_DIR}/rpmbuild/BUILDROOT/${NAME}-${BROOKLYN_VERSION}-${PACKAGE_VERSION}.x86_64/etc/brooklyn/
cp ${SCRIPT_DIR}/conf/logback.xml ${TOP_DIR}/rpmbuild/BUILDROOT/${NAME}-${BROOKLYN_VERSION}-${PACKAGE_VERSION}.x86_64/etc/brooklyn/
cp ${SCRIPT_DIR}/spec/brooklyn.spec ${TOP_DIR}/rpmbuild/SPECS
cp ${SCRIPT_DIR}/daemon/systemd/brooklyn.service ${TOP_DIR}/rpmbuild/BUILDROOT/${NAME}-${BROOKLYN_VERSION}-${PACKAGE_VERSION}.x86_64/etc/systemd/system/

# Ensure correct permissions on files
chmod 600 ${TOP_DIR}/rpmbuild/BUILDROOT/${NAME}-${BROOKLYN_VERSION}-${PACKAGE_VERSION}.x86_64/etc/brooklyn/brooklyn.conf
chmod 644 ${TOP_DIR}/rpmbuild/BUILDROOT/${NAME}-${BROOKLYN_VERSION}-${PACKAGE_VERSION}.x86_64/etc/brooklyn/logback.xml

# Run the build
#rpmbuild -ba ${TOP_DIR}/rpmbuild/SPECS/brooklyn.spec

case ${PACKAGE_TYPE} in
    # Build the rpm package
    rpm)
        FPM_EDITOR="cat >generated_spec_file " fpm -e -s dir -t rpm -n ${NAME} -v ${BROOKLYN_VERSION} -p "${SCRIPT_DIR}/package/" -C "${TOP_DIR}/rpmbuild/BUILDROOT/${NAME}-${BROOKLYN_VERSION}-${PACKAGE_VERSION}.x86_64/" --before-install spec/before_install.centos --after-install spec/after_install.centos --before-remove spec/before_remove.centos --after-remove spec/after_remove.centos --license 'ASL 2.0' --rpm-os linux
        ;;
    # Build the deb package
    deb)
        FPM_EDITOR="cat >generated_spec_file " fpm -e -s dir -t deb -n ${NAME} -v ${BROOKLYN_VERSION} -p "${SCRIPT_DIR}/package/" "${TOP_DIR}/rpmbuild/"
        ;;
    *)
        echo "Allowed package types are: rpm, deb"
        exit 1
esac