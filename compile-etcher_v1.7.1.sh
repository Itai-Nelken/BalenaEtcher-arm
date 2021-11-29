#!/bin/bash

###instructions from here: https://github.com/futurejones/balena-etcher-arm/blob/master/etcher-build/BUILD.md###


#variables
DEPENDS="git python gcc g++ make libx11-dev libxkbfile-dev fakeroot rpm libsecret-1-dev jq python2.7-dev python-pip python-setuptools libudev-dev ruby-dev"
ETCHER_VER="v1.7.1"

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

function install-node() {
    warning-sleep "WARNING: using this method to install Node.js is known to BREAK SYSTEM PERMISSIONS!" 2
    if ! command -v curl >/dev/null ; then
        echo -e "\033[0;31mcurl: command not found.\n\e[39m You need to install curl first. If you are on a debian system, this command should install it: \e[4msudo apt install curl\e[0m"
        exit 1
    fi
    curl -sL https://deb.nodesource.com/setup_15.x | sudo -E bash -
    sudo apt install -y nodejs
}

function install-depends() {
    pkg-manage install "$DEPENDS" || error "Failed to install dependencies!"
    sudo gem install fpm -v 1.10.2 --no-document #note: must be v1.10.2 NOT v1.11.0
    sleep 1
    clear -x
    if ! command -v node >/dev/null ; then
        while true; do
            echo -ne "Node.js and npm aren't installed but required,\ndo you want to install them with nvm (recommended) or with apt from the nodesource repo (NOT RECOMENDED!, KNOWN TO BREAK SYSTEM PERMISSIONS!) [nvm/nodesource]?"
            read answer
            if [[ "$answer" == "nvm" ]]; then
                install-nvm || error "Failed to install nvm!"
                nvm install node --latest-npm || error "nvm failed to install node.js and npm!"
                npm install -g npm@6.14.8 || error "Failed to install npm 6.14.8 (required for building etcher)!"
                break
            elif [[ "$answer" == "nodesource" ]]; then
                warning-sleep "WARNING: using THIS method to install Node.js is KNOWN to BREAK SYSTEM PERMISSIONS!" 2
                while true; do
                    echo -ne "are you sure you want to continue [+/n]?"
                    read answer
                    if [[ "$answer" == "+" ]]; then
                        warning-sleep "BEWARE: I'm not responsible if your system breaks as the result of using this method!\npress [CTRL+C] in the next 10 seconds to exit." 10
                        install-node
                        break
                    elif [[ "$answer" =~ [nNnoNonONO] ]]; then
                        echo -e "OK, you made the better choice :)\nrun the script again."
                        sleep 0.5
                        exit 0
                    else
                        warning-sleep "inalid answer \"$answer\"! please try again" 0
                    fi
                done
                break
            else
                warning-sleep "invalid answer \"$answer\"! please try again" 0
            fi
        done
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
while true; do
  echo -ne "This script will compile and package etcher for arm32/64,\nthis will take around 30 minutes on a pi 4b 4gb on stock clock speeds booting from a samsung evo+ 32gb sd card and consume almost all memory and cpu.\nA fan or at least a heatsink is recommended.\nWARNING: THIS SCRIPT WON'T UNINSTALL THE DEPENDENCIES IT INSTALLS!\nDo you want to continue [y/n]? "
  sleep 0.5
  read answer
  if [[ "$answer" =~ [nN] ]]; then
    echo "exiting in 2 seconds..."
    sleep 2
    exit
    break #in case exit fails (very unlikely)
  elif [[ "$answer" =~ [yY] ]]; then
    true
    break
  else
    echo "invalid answer '$answer'! please try again."
  fi
done

#install all the dependencies
install-depends
sleep 0.5
clear -x
#get directory to build etcher in
while true; do
    echo -ne "Enter full path to the directory where you want to build etcher:\n"
    read -r DIR
    if [ ! -d $DIR ]; then
        echo -e "\e[1mdirectory does not exist, please try again\e[0m"
    else
        echo -e "\e[1mEtcher will be built and packaged here: $DIR\e[0m"
        break
    fi
done
cd "$DIR"
#clone the etcher repo
git clone --recursive https://github.com/balena-io/etcher
cd etcher
clear -x
#get version of etcher to compile and check it out (using git)
#read -p "Enter Etcher version to compile (newest: v1.5.117)" ETCHER_VER
#if [[ $ETCHER_VER == v* ]]; then
#    git checkout $ETCHER_VER || error "Failed to checkout version \"$ETCHER_VER\"!"
#else
#    git checkout v$ETCHER_VER || error "Failed to checkout version \"v$ETCHER_VER\"!"
#fi
git checkout $ETCHER_VER
#install requirements (with pip)
pip install -r requirements.txt
#setup and install NPM modules
make electron-develop
#ask if you want to test if the build worked before packaging it (using npm start)
while true; do
    echo -n "do you want to run a test of etcher to see if compilation worked [y/n]? "
    read answer
    if [[ "$answer" =~ [yY] ]]; then
        echo -ne "$(tput setaf 3)close etcher window to continue to packaging.$(tput sgr 0)\nwaiting for 5 seconds"
        #fancy "progress bar"
        while true;do echo -n .;sleep 1;done &
        sleep 5
        kill $!; trap 'kill $!' SIGTERM
        echo -e "\nStarting Etcher..."
        npm start || error "Etcher failed to start!"
        break
    elif [[ "$answer" =~ [nN] ]];then
      echo "$(tput setaf 3)continuing...$(tput sgr 0)"
      break
    else
      echo "invalid option '$answer', please try again."
    fi
done

##patch build files##
# disable tiffutil in the Makefile as this is a Mac only app and will cause the build to fail
sed -i 's/tiffutil/#tiffutil/g' Makefile  || error "Failed to patch Makefile!"

sleep 1
clear -x
while true; do
    echo -ne "\e[1mDo you want to build a .(d)eb, a (A)ppimage or both [d/A/b]?\e[0m"
    read answer
    if [[ "$answer" =~ [dD] ]]; then
    echo -n "patching build.sh to build only a .deb..."
    #restrict output to .deb package only to save build time
    sed -i 's/TARGETS="deb rpm appimage"/TARGETS="deb"/g' scripts/resin/electron/build.sh || error "Failed to patch 'build.sh' script to only build a deb!"
    out="deb"
    echo "done"
    break
    elif [[ "$answer" =~ [Aa] ]]; then
    echo -n "patching build.sh to build only a AppImage..."
    #restrict output to .AppImage package only to save build time
    sed -i 's/TARGETS="deb rpm appimage"/TARGETS="appimage"/g' scripts/resin/electron/build.sh || error "Failed to patch 'build.sh' script to only build a AppImage!"
    out="appimage"
    echo "done"
    break
    elif [[ "$answer" =~ [bB] ]]; then
    echo -n "patching build.sh to build both a .deb and AppImage..."
    sed -i 's/TARGETS="deb rpm appimage"/TARGETS="deb appimage"/g' scripts/resin/electron/build.sh || error "Failed to patch 'build.sh' script to build both a deb and a AppImage!"
    out=all
    echo "done"
    break
    else
        echo -e "\e[31minvalid answer \"$answer\"! please try again.\e[0m"
    fi
done

##compile and build etcher##
# use USE_SYSTEM_FPM="true" to force the use of the installed FPM version
USE_SYSTEM_FPM="true" make electron-build  || error "Failed to run \"USE_SYSTEM_FPM="true" make electron-buil\"!"

#get the finished output's name
if [[ "$out" == "deb" ]]; then
    OUTNAME="$(basename $DIR/etcher/dist/balena-etcher-electron*.deb)"
    sleep 1
    clear -x
    echo "The deb is in \"$DIR/etcher/dist/$OUTNAME\"."
    echo "install it with \"sudo apt -f install ./$DIR/etcher/dist/$OUTNAME\""
elif [[ "$out" == "appimage" ]]; then
    OUTNAME="$(basename $DIR/etcher/dist/balena-etcher-electron*.AppImage)"
    sleep 1
    clear -x
    echo "The AppImage is in \"$DIR/etcher/dist/$OUTNAME\"."
elif [[ "$out" == "all" ]]; then
    DEBNAME="$(basename $DIR/etcher/dist/balena-etcher-electron*.deb)"
    OUTNAME="$(basename $DIR/etcher/dist/balena-etcher-electron*.AppImage)"
    echo "The deb is in \"$DIR/etcher/dist/$DEBNAME\""
    echo -e "The AppImage is in \"$DIR/etcher/dist/$OUTNAME\"\n"
    echo "Install the deb with \"sudo apt -f install .$DIR/etcher/dist/$OUTNAME\""
fi
sleep 2
echo "DONE!"
exit 0
