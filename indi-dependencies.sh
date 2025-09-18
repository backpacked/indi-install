#!/bin/bash

sudo apt update && sudo apt upgrade

echo "Installing system dependencies for INDI Core and INDI 3rd party..."

# kstars libraries 
sudo apt -y install build-essential cmake git libstellarsolver-dev libeigen3-dev libcfitsio-dev zlib1g-dev extra-cmake-modules \
  libkf5plotting-dev libqt5svg5-dev libkf5xmlgui-dev libkf5kio-dev kinit-dev libkf5newstuff-dev libkf5doctools-dev \
  libkf5notifications-dev qtdeclarative5-dev libkf5crash-dev gettext libnova-dev libgsl-dev libraw-dev libkf5notifyconfig-dev \
  wcslib-dev libqt5websockets5-dev xplanet xplanet-images qt5keychain-dev libsecret-1-dev breeze-icon-theme libqt5datavisualization5-dev

# indi and indi-3rd-party libs
sudo apt-get -y install libnova-dev libcfitsio-dev libusb-1.0-0-dev zlib1g-dev libgsl-dev build-essential cmake git \
 libjpeg-dev libcurl4-gnutls-dev libtiff-dev libfftw3-dev libftdi-dev libgps-dev libraw-dev libdc1394-dev libgphoto2-dev \
 libboost-dev libboost-regex-dev librtlsdr-dev liblimesuite-dev libftdi1-dev libavcodec-dev libavdevice-dev libzmq3-dev libudev-dev \
 cdbs dkms fxload libkrb5-dev libtheora-dev libindi-dev libev-dev libindi-dev

# stellasolver libs
# sudo apt install git cmake qtbase5-dev libcfitsio-dev libgsl-dev wcslib-dev
sudo apt -y install qtbase5-dev wcslib-dev

# phd2 libs
sudo apt -y install libwxgtk3.2-dev libeigen3-dev

