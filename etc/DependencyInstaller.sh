#!/bin/bash

set -euo pipefail

# Make sure we are on the correct folder before beginning
if [[ "$OSTYPE" == "darwin"* ]]; then
    cd "$(dirname $(perl -e 'use Cwd "abs_path";print abs_path(shift)' $0))/../"
else
    cd "$(dirname $(readlink -f $0))/../"
fi

# package versions
klayoutVersion=0.27.10

_installORDependencies() {
    ./tools/OpenROAD/etc/DependencyInstaller.sh ${OR_INSTALLER_ARGS}
}

_installCommon() {
    # install pandas
    pip3 install pandas
}

_installCentosCleanUp() {
    yum clean -y all
    rm -rf /var/lib/apt/lists/*
}

_installCentosPackages() {
    yum update -y
    yum install -y \
        libffi-devel \
        tcl \
        time \
        ruby \
        ruby-devel \
        tcl-devel 

    yum install -y https://www.klayout.org/downloads/CentOS_7/klayout-${klayoutVersion}-0.x86_64.rpm
}

_installUbuntuCleanUp() {
    apt-get autoclean -y
    apt-get autoremove -y
}

_installUbuntuPackages() {
    export DEBIAN_FRONTEND="noninteractive"
    apt-get -y update
    apt-get -y install \
        libffi-dev \
        tcl \
        tcl-dev \
        time \
        ruby \
        ruby-dev \
        libz-dev \
        python3-pip \
        qttools5-dev \
        libqt5xmlpatterns5-dev \
        qtmultimedia5-dev \
        libqt5multimediawidgets5 \
        libqt5svg5-dev

    lastDir="$(pwd)"

    # temp dir to download and compile
    baseDir=/tmp/installers
    mkdir -p "${baseDir}"
    cd ${baseDir}

    # install KLayout
    if [[ $1 == 20.04 ]]; then
        klayoutChecksum=8076dadfb1b790b75d284fdc9c90f70b
    else
        klayoutChecksum=2fb355f0e19d69be8535722185f983cc
    fi
    wget https://www.klayout.org/downloads/Ubuntu-${1%.*}/klayout_${klayoutVersion}-1_amd64.deb
    md5sum -c <(echo "${klayoutChecksum} klayout_${klayoutVersion}-1_amd64.deb") || exit 1
    dpkg -i klayout_${klayoutVersion}-1_amd64.deb

    cd ${lastDir}
    rm -rf "${baseDir}"
}

_installDarwinPackages() {
    brew install libffi tcl-tk ruby
    brew install python libomp
    brew link --force libomp
    brew install --cask klayout
}

_help() {
    cat <<EOF

All arguments and flags are only applicable for OpenROAD dependencies
Usage: $0
                                # Installs all of OpenROAD's dependencies no
                                #     need to run -base or -common. Requires
                                #     privileged access.
                                #
       $0 -base
                                # Installs OpenROAD's dependencies using
                                #     package managers (-common must be
                                #     executed in another command).
       $0 -common
                                # Installs OpenROAD's common dependencies
                                #     (-base must be executed in another
                                #     command).
       $0 -prefix=DIR
                                # Installs common dependencies in an existing
                                #     user-specified directory. Only used
                                #     with -common. This flag cannot be used
                                #     with sudo or with root access.
       $0 -local
                                # Installs common dependencies in
                                #    "$HOME/.local". Only used with
                                #    -common. This flag cannot be used with
                                #    sudo or with root access.
EOF
    exit "${1:-1}"
}

# default args
OR_INSTALLER_ARGS=""

# default values, can be overwritten by cmdline args
while [ "$#" -gt 0 ]; do
    case "${1}" in
        -h|-help)
            _help 0
            ;;
        -base)
            OR_INSTALLER_ARGS="${OR_INSTALLER_ARGS} -base"
            ;;
        -common)
            OR_INSTALLER_ARGS="${OR_INSTALLER_ARGS} -common"
            ;;
        -local)
            OR_INSTALLER_ARGS="${OR_INSTALLER_ARGS} -local"
            ;;
        -prefix=*)
            OR_INSTALLER_ARGS="${OR_INSTALLER_ARGS} $1"
            ;;
        *)
            echo "unknown option: ${1}" >&2
            _help
            ;;
    esac
    shift 1
done

platform="$(uname -s)"
case "${platform}" in
    "Linux" )
        if [[ -f /etc/os-release ]]; then
            os=$(awk -F= '/^NAME/{print $2}' /etc/os-release | sed 's/"//g')
        else
            os="Unidentified OS, could not find /etc/os-release."
        fi
        ;;
    "Darwin" )
        os="Darwin"
        ;;
    *)
        echo "${platform} is not supported" >&2
        _help
        ;;
esac

case "${os}" in
    "CentOS Linux" )
        _installORDependencies
        _installCentosPackages
        _installCommon
        _installCentosCleanUp
        ;;
    "Ubuntu" )
        version=$(awk -F= '/^VERSION_ID/{print $2}' /etc/os-release | sed 's/"//g')
        _installORDependencies
        _installUbuntuPackages "${version}"
        _installCommon
        _installUbuntuCleanUp
        ;;
    "Darwin" )
        _installORDependencies
        _installDarwinPackages
        _installCommon
        ;;
    *)
        echo "unsupported system: ${os}" >&2
        _help
        ;;
esac