#!/bin/bash

ETCHER_VER="v1.5.117"

function install-node-from-nodesource() {
  while true; do
    read -p "nvm failed to install node.js and npm, would you like to install it from the nodesource apt repo? WARNING: it might break system permissions! (y/n)?" answer
    if [[ "$answer" =~ [yY] ]]; then
      curl -sL https://deb.nodesource.com/setup_15.x | sudo -E bash -
      sudo apt install -y nodejs || echo "apt failed to install node.js!" && sleep 1 && exit 1
      break
    elif [[ "$answer" =~ [nN] ]]; then
      echo "OK"
      sleep 0.5
      break
    else
      echo "invalid answer '$answer'! please try again."
    fi
  done
}

function install-node() {
  echo "please run: wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash"
  echo "and then run this script again"
  exit
  #curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash || error "Failed to install nvm!"
  #export NVM_DIR="$HOME/.nvm"
  #[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
  #[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
  #if [[ -f "$HOME/.bashrc" ]]; then
  #  source ~/.bashrc
  #fi
  #if [[ "$ARCH" == "armhf" ]]; then
  #  sed -i 's/^  nvm_echo "${NVM_ARCH}"/  NVM_ARCH=armv7l ; nvm_echo "${NVM_ARCH}"/g' "$NVM_DIR/nvm.sh"
  #fi
  #chmod +x $NVM_DIR/nvm.sh
  #nvm install v15.12.0 --latest-npm || install-node-from-nodesource || echo "failed to install node.js and npm!" && sleep 1 && exit 1
}

function compile-etcher() {
  cd ~/Downloads
  echo "$(tput setaf 3)installing dependencies...$(tput sgr 0)"
  sudo apt install -y curl git python gcc g++ make libx11-dev libxkbfile-dev fakeroot rpm libsecret-1-dev jq python2.7-dev python-pip python-setuptools libudev-dev jq
  sudo apt install -y ruby-dev
  sudo gem install fpm -v 1.10.2 --no-document

  if ! command -v curl >/dev/null ; then
    echo -e "\033[0;31mcurl: command not found.\e[39mYou need to install curl first. If you are on a debian system, this command should install it:\e[4msudo apt install curl\e[0m"
    exit 1
  fi
  #Checking if using armv6
  if [ ! -z "$(cat /proc/cpuinfo | grep ARMv6)" ];then
    echo -e "\e[31marmv6 CPU not supported!\e[0m"
    exit 1
  fi
  #check that OS arch is armhf
  ARCH="$(uname -m)"
  if [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]] || [[ "$ARCH" == "armv7l" ]] || [[ "$ARCH" == "armhf" ]]; then
    if [ ! -z "$(file "$(readlink -f "/sbin/init")" | grep 64)" ];then
        ARCH="arm64"
    elif [ ! -z "$(file "$(readlink -f "/sbin/init")" | grep 32)" ];then
        ARCH="armhf"
    else
        echo -e "$(tput setaf 1)$(tput bold)Can't detect OS architecture! something is very wrong!$(tput sgr 0)"
        exit 1
    fi
  else
    echo -e "$(tput setaf 1)$(tput bold)ERROR: '$ARCH' isn't a supported architecture!\nthis script is only intended to run on arm32 and arm64!$(tput sgr 0)"
    exit 1
  fi

  if command -v node >/dev/null ; then
    NODE=1
  fi
  if [[ $NODE == 1 ]]; then
    echo "Node.js and npm are needed."
    echo -n "do you want to install them using 'nvm' (recommended) or the nodesource repo (known to break system permissions!) [nvm/nodesource]?"
    read answer
    if [[ $answer == "nvm" ]]; then
      install-node
    elif [[ $answer == "nodesource" ]]; then
      install-node-from-nodesource
    else
      echo "invalid answer."
      exit 1
    fi
  fi

  sleep 4
  clear -x
  echo "$(tput setaf 3)cloning etcher repo and checking out realease ($ETCHER_VER)$(tput sgr 0)"
  cd ~/Downloads
  git clone --recursive https://github.com/balena-io/etcher
  cd etcher
  git checkout $ETCHER_VER
  echo "$(tput setaf 3)installing requirements...$(tput sgr 0)"
  pip install -r requirements.txt
  echo "$(tput setaf 3)setting up and installing NPM modules...$(tput sgr 0)"
  make electron-develop
  sleep 4
  clear -x
  while true; do
    echo -n "do you want to run a test of etcher to see if compile worked [y/n]? "
    read answer
    if [[ "$answer" =~ [yY] ]]; then
      echo -e "$(tput setaf 3)close etcher window to continue to packaging.\nwaiting for 5 seconds...$(tput sgr 0)"
      sleep 5
      npm start
      break
    elif [[ "$answer" =~ [nN] ]];then
      echo "$(tput setaf 3)continuing...$(tput sgr 0)"
      break
    else
      echo "invalid option '$answer', please try again."
    fi
  done
  echo "$(tput setaf 3)building & packaging etcher into a .deb file...$(tput sgr 0)"
  sed -i 's/tiffutil/#tiffutil/g' Makefile 
  sed -i 's/TARGETS="deb rpm appimage"/TARGETS="deb"/g' scripts/resin/electron/build.sh
  USE_SYSTEM_FPM="true" make electron-build
  sleep 5
  clear -x
  echo ".deb file will be in ~/Downloads/etcher/dist/"
}

clear -x
while true; do
  echo -ne "this script will compile and package etcher $ETCHER_VER for arm32/64, this will take around 30 minutes on a pi 4 on stock clock speed and consume almost all    memory and cpu. a fan or at least a heatsink is recommended for the pi 4.\nWARNING: THIS SCRIPT WON'T UNINSTALL THE DEPENDENCIES IT INSTALLS!\nDo you want to continue [y/n]? "
  sleep 0.5
  read answer
  if [[ "$answer" =~ [nN] ]]; then
    echo "exiting in 5 seconds"
    sleep 5
    exit
    break #in case exit fails (very unlikely)
  elif [[ "$answer" =~ [yY] ]]; then
    compile-etcher 
    echo "$(tput setaf 3)exiting in 10 seconds... $(tput sgr 0)"
    sleep 10
    exit
    break #in case exit fails (very unlikely)
  else
    echo "invalid answer '$answer, please try again"
  fi
done
