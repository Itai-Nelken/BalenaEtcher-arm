# Etcher-arm-32-64
balena-etcher v1.5.109 compiled from source for armhf and arm64 for the RaspberryPi and other arm computers.

![Etcher on rpi screenshot](/screenshots/etcher.png)


## Installation:
you can install this version of Etcher in [Pi-Apps](https://github.com/Botspot/pi-apps) 
or install manually: download the .deb file for your system architecture, (armhf for 32bit, and arm64 for 64bit) and open it with the package installer or open terminal in the directory where th .deb is and type 
```sh-session
$ sudo dpkg -i <the file name.deb>
```
## Uninstallation
to uninstall, type in terminal the following:
```sh-session
$ sudo apt purge -y balena-etcher-electron
```

