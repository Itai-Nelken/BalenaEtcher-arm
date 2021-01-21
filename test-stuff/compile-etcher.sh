#!/bin/bash

#check if CPU is ARM (32bit or 64bit)
ARCH=$(uname -m)
if [ "${ARCH}" != "aarch64" ]; then
  
  #check if CPU is ARM 32bit
  ARCH=$(uname -m)
  if [ "${ARCH}" != "armv7l" "armhf" ]; then
   echo "your cpu architecture isn't ARM, this script is only intended for arm cpu's"
   echo "exiting in 5 seconds..."
   sleep 5; exit
 else
  echo "CPU architecture is ARM 32bit"
  ARCH1="32bit ARM"
 fi

else
  echo "CPU architecture is ARM 64bit"
  ARCH1="ARM 64bit"
fi


#ask if user wants to continue
clear
echo this script will compile and package etcher for $ARCH1
echo "this will take around 30 minutes on a pi 4 on stock clock speed and consume almost all memory and cpu during some parts."
echo "a fan or at least a heatsink is recommended for the pi 4. Do you want to continue? [y/n]"
read answer
if [ "$answer" == n ];then
 echo "exiting in 5 seconds"
 sleep 5
 exit
fi
if [ "$answer" == y ];then
 echo "continuing..."
 sleep 1
fi

#ask for version to compile  
echo "Enter etcher version to compile (e.g 1.5.113): "  
read VERSION  

#if no user input, set to v1.5.112 (doesn't work yet)
if [[ "$VERSION" == "" ]];then
 VERSION=1.5.112
fi

#tell user what version will be compiled
echo "version compiled will be v$VERSION"

#ask user to install dependencies and install/skip 
echo -n "install dependencies (required unless already installed (e.g running script 2nd time)), **answering no isn't recommended** [y/n]"
 read answer
 if [ "$answer" == n ];then
 echo "dependencies won't be installed. BEWARE: compiling and packaging will fail unless dependencies are already installed"
fi
if [ "$answer" == y ];then
 cd ~/Downloads
 echo "$(tput setaf 3)installing dependencies...$(tput sgr 0)"
 sudo apt update
 sudo apt-get install -y git python gcc g++ make libx11-dev libxkbfile-dev fakeroot rpm libsecret-1-dev jq python2.7-dev python-pip python-setuptools libudev-dev jq
 sudo apt-get install -y ruby-dev
 sudo gem install fpm -v 1.10.2 --no-document
 curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
 sudo apt-get install -y nodejs
 sleep 4
 clear
fi

#clone etcher repo and checkout realease to be compiled
echo "$(tput setaf 3)cloning etcher repo and checking out realease (your input)$(tput sgr 0)"
git clone --recursive https://github.com/balena-io/etcher
cd etcher
git checkout $VERSION

#install requirements
echo "$(tput setaf 3)installing requirements...$(tput sgr 0)"
pip install -r requirements.txt

#set up and install npm modules
echo "$(tput setaf 3)setting up and installing NPM modules...$(tput sgr 0)"
make electron-develop
sleep 4
clear

#ask user to run a test of etcher to see if compile worked and do it/skip it
echo -n "do you want to run a test of etcher to see if compile worked? [y/n] "
read answer
if [ "$answer" == y ];then
 echo "$(tput setaf 3)close etcher window to continue to packaging.$(tput sgr 0)"
 sleep 5
 npm start
fi
if [ "$answer" == n ];then
 echo "$(tput setaf 3)continuing...$(tput sgr 0)"
fi

#build and pacakge etcher to a .deb package
echo "$(tput setaf 3)building & packaging etcher into a .deb file...$(tput sgr 0)"
sed -i 's/tiffutil/#tiffutil/g' Makefile 
sed -i 's/TARGETS="deb rpm appimage"/TARGETS="deb"/g' scripts/resin/electron/build.sh
USE_SYSTEM_FPM="true" make electron-build
sleep 5
clear

echo ".deb file will be in ~/Downloads/etcher/dist/"

echo -n "do you want to delete this script? [y/n] "
read answer
if [ "$answer" == y ];then
rm compile-etcher.sh
fi
if [ "$answer" == n ];then
 echo "$(tput setaf 3)the script WILL NOT be deleted$(tput sgr 0)"
fi

echo "$(tput setaf 3)exiting in 10 seconds... $(tput sgr 0)"
sleep 10
exit
