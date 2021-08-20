#!/bin/bash

# error function, prints text in red then exits
function error {
  echo -e "\e[91m$1\e[39m"
  exit 1
}

# check internet, if none, exit
printf "checking if you are online..."
wget -q --spider http://github.com
if [ $? -eq 0 ]; then
    echo "Online. Continuing."
else
    error "Offline. Go connect to the internet then run the script again."
fi

# defining variables
EMAIL="$(cat /home/pi/cronscripts/etcher/email)"
GPGPASS="$(cat /home/pi/cronscripts/etcher/gpgpass)"
last="$(cat /home/pi/cronscripts/etcher/local_version.txt)"
echo "Last upload was: $last"
release=$(curl -s https://api.github.com/repos/Itai-Nelken/Etcher-arm-32-64/releases/latest | grep "tag_name" | sed "s/[\",tag_name: ]//g")
echo "Last saved version is: $release"
PKGDIR="/home/pi/Documents/balenaetcher-debs/debian/"
REPODIR="/home/pi/Documents/balenaetcher-debs/"

if [[ "$last" != "$release" ]]; then
        rm -rf $PKGDIR/*
        LATEST=$(curl -s https://api.github.com/repos/Itai-Nelken/Etcher-arm-32-64/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")' | tr -d 'v')
        curl -s https://api.github.com/repos/Itai-Nelken/Etcher-arm-32-64/releases/latest \
          | grep browser_download_url \
          | grep 'armv7l.deb"' \
          | cut -d '"' -f 4 \
          | xargs -n 1 curl -L -o $PKGDIR/balena-etcher-electron-$LATEST-armhf.deb

        curl -s https://api.github.com/repos/Itai-Nelken/Etcher-arm-32-64/releases/latest \
          | grep browser_download_url \
          | grep 'arm64.deb"' \
          | cut -d '"' -f 4 \
          | xargs -n 1 curl -L -o $PKGDIR/balena-etcher-electron-$LATEST-arm64.deb
        COMPLETE=$(curl -s https://api.github.com/repos/Itai-Nelken/Etcher-arm-32-64/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
        echo $COMPLETE > /home/pi/cronscripts/etcher/local_version.txt
        cd $PKGDIR
        dpkg-scanpackages --multiversion . > Packages
        gzip -k -f Packages
        apt-ftparchive release . > Release
        gpg --default-key "${EMAIL}" --batch --pinentry-mode="loopback" --passphrase="$GPGPASS" -abs -o - Release > Release.gpg
	    gpg --default-key "${EMAIL}" --batch --pinentry-mode="loopback" --passphrase="$GPGPASS" --clearsign -o - Release > InRelease
        cd $REPODIR
        git pull origin master
        git add .
        git commit -m "Updated etcher to $COMPLETE"
        git push origin master
    else
        echo "not today :("
    fi
fi
