# <img src="/screenshots/balena-etcher.png" alt="drawing" width="60"/>Etcher-arm-32-64
balena-etcher v1.5.109 and later compiled from [source](https://github.com/balena-io/etcher) for armhf and arm64 for the [Raspberry Pi](https://www.raspberrypi.org) and other [ARM](https://en.wikipedia.org/wiki/ARM_architecture) based [linux](https://en.wikipedia.org/wiki/Linux) computers.

![Etcher on rpi screenshot](/screenshots/etcher.png)


## Install
It is recommended to install this version of Etcher from Pi-Apps (click the badge bellow for more info about pi-apps) <br> 
[![badge](https://github.com/Botspot/pi-apps/blob/master/icons/badge.png?raw=true)](https://github.com/Botspot/pi-apps)  
but if you prefer, you can install manually: 
1) download the .deb file for your system architecture from the [releases](https://github.com/Itai-Nelken/Etcher-arm-32-64/releases) (armhf is 32bit arm, and arm64 is 64bit arm).
2) open the .deb file with a package installer (just double click it) if you have one installed, or open terminal in the directory where the .deb is and type 
```sh-session
$ sudo dpkg -i the-file-name.deb
```
but replace `the-file-name.deb` with the name of the .deb file you downloaded.

## compile
use my [compile script](compile-etcher_v1.5.110.sh), this script simply runs the instructions found [here](https://github.com/futurejones/balena-etcher-arm/blob/master/etcher-build/BUILD.md). to run it, download the [script](compile-etcher_v1.5.111.sh), open terminal in the directory where the script is, and type:
```sh-session
$ sudo chmod +x compile-etcher_v1.5.110.sh && ./compile-etcher_v1.5.110.sh
```
alternately compile, build, and package manually with the instructions [here](https://github.com/futurejones/balena-etcher-arm/blob/master/etcher-build/BUILD.md)
but replace this line: 
```sh-session
$ git checkout v1.5.63
```
with this line:
```sh-session
$ git checkout v1.5.111
```
so you compile v1.5.111 (newest) instead of v1.5.63.

## Uninstall
If you installed from [Pi-Apps](https://github.com/Botspot/pi-apps), the you can also uninstall it from there.
to manually uninstall, type the following in terminal :
```sh-session
$ sudo apt purge -y balena-etcher-electron
```

## Credits
Big thanks to futurejones for finding a way to compile Etcher for ARM.

- [RaspberryPi Forums thread](https://www.raspberrypi.org/forums/viewtopic.php?f=62&t=255205&start=25).
- [futurejones github repo for balena-etcher-arm](https://github.com/futurejones/balena-etcher-arm)
