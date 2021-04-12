#!/bin/bash

###functions###
function error() {
    echo -e "$(tput setaf 1)$(tput bold)$1$(tput sgr 0)"
    exit 1
}

function warning() {
    echo -e "$(tput setaf 3)$(tput bold)$1$(tput sgr 0)"
    sleep 5
}

function warning-sleep() {
    #USAGE:
    #warning-sleep "warning: something happened" 2
    #
    #$1 is the text
    #$2 is the amount of seconds to sleep
    echo -e "$(tput setaf 3)$(tput bold)$1$(tput sgr 0)"
    sleep $2
}

function pkg-manage() {
    #USAGE:
    #usage: pkg-manage install "package1 package2 package3"
    #pkg-manage uninstall "package1 package2 package3"
    #pkg-manage check "packag1 package2 package3"
    #pkg-manage clean
    #
    #$1 is the operation: install or uninstall
    #$2 is the packages to operate on.
    if [[ "$1" == "install" ]]; then
        TOINSTALL="$(dpkg -l $2 2>&1 | awk '{if (/^D|^\||^\+/) {next} else if(/^dpkg-query:/) { print $6} else if(!/^[hi]i/) {print $2}}' | tr '\n' ' ')"
        sudo apt -f -y install $TOINSTALL || sudo apt -f -y install "$TOINSTALL"
    elif [[ "$1" == "uninstall" ]]; then
        sudo apt purge $2 -y
    elif [[ "$1" == "check" ]]; then
        TOINSTALL="$(dpkg -l $2 2>&1 | awk '{if (/^D|^\||^\+/) {next} else if(/^dpkg-query:/) { print $6} else if(!/^[hi]i/) {print $2}}' | tr '\n' ' ')"  
    elif [[ "$1" == "clean" ]]; then
        sudo apt clean
        sudo apt autoremove -y
        sudo apt autoclean
    else
        error "operation not specified!"
    fi
}

function install-nvm() {
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
	export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
}

function install-depends() {
    pkg-manage install "$DEPENDS" || error "Failed to install dependencies!"
    sudo gem install fpm -v 1.10.2 --no-document #note: must be v1.10.2 NOT v1.11.0
    if ! command -v node >/dev/null ; then
        install-nvm || error "Failed to install nvm!"
        nvm install node --latest-npm || error "nvm failed to install node.js and npm!"
        npm install -g npm@6.14.8 || error "Failed to install npm 6.14.8 (required for building etcher)!"
    fi

}

#####things start to get done here#####

#check that system is compatible
#is CPU armv6?
if [ ! -z "$(cat /proc/cpuinfo | grep ARMv6)" ];then
  error "armv6 CPU not supported!"
fi

#check if arch is arm
ARCH="$(uname -m)"
if [[ "$ARCH" == "armv7l" ]] || [[ "$ARCH" == "armhf" ]] || [[ "$ARCH" == "arm64" ]] || [[ "$ARCH" == "aarch64" ]]; then
    if [ ! -z "$(file "$(readlink -f "/sbin/init")" | grep 64)" ];then
        ARCH="arm64"
    elif [ ! -z "$(file "$(readlink -f "/sbin/init")" | grep 32)" ];then
        ARCH="armhf"
    else
        error "Can't detect OS architecture! something is very wrong!"
    fi
else
    error "Unsuported architecture! this script is only intended to be run on linux arm devices."
fi
local=$(cat local_version.txt)
#local="v1.5.116" #newest: v1.5.117
echo "last saved version is: $local"
release=$(curl -s https://api.github.com/repos/balena-io/etcher/releases/latest | grep "tag_name" | sed "s/[\",tag_name: ]//g")
echo "latest version is: $release"
if [[ "$release" > "$local" ]]; then
    #compile and package etcher
    echo "today!"
    #variables
    DEPENDS="git python gcc g++ make libx11-dev libxkbfile-dev fakeroot rpm libsecret-1-dev jq python2.7-dev python-pip python-setuptools libudev-dev ruby-dev"
    install-depends
    DIR="$HOME/Documents/etcher-build"
    if [[ ! -d "$DIR" ]]; then
        mkdir $DIR
    fi
    cd "$DIR"
    #clone the etcher repo
    git clone --recursive https://github.com/balena-io/etcher
    cd "etcher"
    git checkout $release
    #install requirements (with pip)
    pip install -r requirements.txt
    #setup and install NPM modules
    make electron-develop
    #npm start

    ##patch build files##
    # disable tiffutil in the Makefile as this is a Mac only app and will cause the build to fail
    sed -i 's/tiffutil/#tiffutil/g' Makefile  || error "Failed to patch Makefile!"
    sed -i 's/TARGETS="deb rpm appimage"/TARGETS="deb appimage"/g' scripts/resin/electron/build.sh || error "Failed to patch 'build.sh' script to build both a deb and a AppImage!"
    ##compile and build etcher##
    # use USE_SYSTEM_FPM="true" to force the use of the installed FPM version
    USE_SYSTEM_FPM="true" make electron-build  || error "Failed to run \"USE_SYSTEM_FPM="true" make electron-buil\"!"
    mv $DIR/etcher/dist/*.AppImage $DIR || sudo mv $DIR/etcher/dist/*.AppImage $DIR
    mv $DIR/etcher/dist/*.deb $DIR || sudo mv $DIR/etcher/dist/*.deb $DIR
else
    echo "not today :("
fi

#write new release
echo "$release" > local_version.txt
