#!/bin/bash

echo -n "this script will compile and package etcher v1.5.110 for arm32/64, this will take around 30 minutes on a pi 4on stock clock speed. a fan or at least a heatsink is recommended for the pi 4. Do you want to continue? [y/n] "
  read answer
  if [ "$answer" == n ];then
   echo "exiting in 5 seconds"
   sleep 5
   exit
  fi
  if [ "$answer" == y ];then
   
   echo "installing dependencies..."
   sudo apt-get install -y git python gcc g++ make libx11-dev libxkbfile-dev fakeroot rpm    libsecret-1-dev jq python2.7-dev pip python-setuptools libudev-dev
   sudo apt-get install ruby-dev
   sudo gem install fpm -v 1.10.2 --no-document
   curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
   sudo apt-get install -y nodejs

   echo "cloning etcher repo and checking out realease (v1.5.110)"
   git clone --recursive https://github.com/balena-io/etcher
   cd etcher
   git checkout v1.5.110

   echo "installing requirements..."
   pip install -r requirements.txt

   echo "setting up and installing NPM modules..."
   make electron-develop
   
   echo -n "do you want to run a test of etcher to see if compile worked? [y/n] "
  read answer
  if [ "$answer" == n ];then
   echo "clode etcher window to continue to packaging."
   sleep 5
   npm start
  fi
  if [ "$answer" == y ];then
   
   echo "building & packaging etcher into a .deb file..."
   sed -i 's/tiffutil/#tiffutil/g' Makefile 
   sed -i 's/TARGETS="deb rpm appimage"/TARGETS="deb"/g' scripts/resin/electron/build.sh
   USE_SYSTEM_FPM="true" make electron-build
   
  fi
   
  fi
  
sleep 5
clear
echo ".deb file will be in /etcher/dist/
  

echo "exiting in 10 seconds..."
sleep 10
exit





