#!/bin/bash

# Set compiler flags
export CFLAGS="-march=native -w -Wno-psabi -D_FILE_OFFSET_BITS=64"
export CXXFLAGS="-march=native -w -Wno-psabi -D_FILE_OFFSET_BITS=64"

# Get the script's directory
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INSTALL_LIBXISF=false
INSTALL_STELLAR=false
INSTALL_KSTARS=false
INSTALL_PHD=false

# Repos
LIBXISF_GIT="https://gitea.nouspiro.space/nou/libXISF.git"
INDI_CORE_GIT="https://github.com/indilib/indi.git"
INDI_3RDPARTY_GIT="https://github.com/indilib/indi-3rdparty.git"
STELLAR_GIT="https://github.com/rlancaste/stellarsolver.git"
KSTARS_GIT="https://invent.kde.org/education/kstars.git"
PHD2_GIT="https://github.com/OpenPHDGuiding/phd2.git"

# Function to display usage
usage() {
  echo "Usage: $0 [OPTIONS]"
  echo "Options:"
  echo "  --libxisf             Install LibXISF"
  echo "  --stellarsolver       Install stellarsolver"
  echo "  --kstars              Install KStars"
  echo "  --phd2 [VERSION]      Install PHD2 (optional: specify version, default: v2.6.12)"
  echo "  --all                 Install Everything"
  echo "  --help                Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0                                    # Show Usage"
  echo "  $0 --libxisf                          # Install LibXISF"
  echo "  $0 --kstars --phd2                    # Install KStars + PHD2"
  echo "  $0 --all                              # Install liXISF + stellarsolver + KStars + PHD2"
}

# Show usage and exit if no arguments were provided
if [[ $# -eq 0 ]]; then
  usage
  exit 0
fi

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --libxisf)
      INSTALL_LIBXISF=true
      shift
      ;;
    --stellarsolver)
      INSTALL_STELLAR=true
      shift
      ;;
    --kstars)
      INSTALL_KSTARS=true
      shift
      ;;
    --phd2)
      INSTALL_PHD=true
      shift
      ;;
    --all)
      INSTALL_LIBXISF=true
      INSTALL_STELLAR=true
      INSTALL_KSTARS=true
      INSTALL_PHD=true
      ;;
    --help)
      usage
      exit 0
      ;;
    "")
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

JOBS=$(grep -c ^processor /proc/cpuinfo)

# 64 bit systems need more memory for compilation
if [ $(getconf LONG_BIT) -eq 64 ] && [ $(grep MemTotal < /proc/meminfo | cut -f 2 -d ':' | sed s/kB//) -lt 5000000 ]; then
    echo "Low memory limiting to JOBS=2"
    JOBS=2
  fi


sudo apt update && sudo apt upgrade -y

DEPLOY_DIR=${DEPLOY_DIR:-$HOME/Projects}
ROOTDIR="$DEPLOY_DIR/astropi-deploy"

[ ! -d "$DEPLOY_DIR" ] && mkdir -p "$DEPLOY_DIR"
[ ! -d "$ROOTDIR" ] && mkdir -p "$ROOTDIR"
cd "$ROOTDIR"

# Install LibXISF if requested
if [ "$INSTALL_LIBXISF" = true ]; then
  cd "$ROOTDIR"

  echo "Clone libXISF git repo depth=1"
  git clone --depth=1 https://gitea.nouspiro.space/nou/libXISF.git libXISF

  cd libXISF

  cmake -B build -DUSE_BUNDLED_ZLIB=OFF -S .
  cmake --build build --parallel
  cmake --install build

  cd "$ROOTDIR"

else
  echo "Skipping LibXISF installation"
fi


# Install stellarsolver if requested
if [ "$INSTALL_STELLAR" = true ]; then
  cd "$ROOTDIR"
  
  echo "Clone stellarsolver git repo depth=1."
  git clone --depth=1 https://github.com/rlancaste/stellarsolver.git stellarsolver

  cd stellarsolver/linux-scripts

  ./installStellarSolverTesterQt6.sh

  cd "$ROOTDIR"
else
  echo "Skipping stellarsolver installation"
fi

# Install KStars if requested
if [ "$INSTALL_KSTARS" = true ]; then
  cd "$ROOTDIR"
  echo "Installing KStars with Indi using Flatpak."
  wget https://raw.githubusercontent.com/ikarustechnologies/indi-firmware/main/kstars.sh
  bash kstars.sh

  cd "$ROOTDIR"
else
  echo "Skipping KStars installation"
fi

# Install PHD2 if requested
if [ "$INSTALL_PHD" = true ]; then
  cd "$ROOTDIR"
  PHD2_DEPLOY_DIR=$ROOTDIR/build_phd2

  # Cleanup phd2 installs
  if [ -d "$PHD2_DEPLOY_DIR" ]; then
      echo "Cleaning up previous PHD2 installations..."
      find "$PHD2_DEPLOY_DIR" -name "install_manifest.txt" -exec cat {} \; | sudo xargs rm -f 2>/dev/null || true
  fi

  # Install Dependencies
  echo "Installing system dependencies for PHD2..."
  sudo apt-get install build-essential git cmake pkg-config libwxgtk3.2-dev wx-common wx3.2-i18n libindi-dev \
  libnova-dev gettext zlib1g-dev libx11-dev libcurl4-gnutls-dev libopencv-dev libeigen3-dev libgtest-dev

  echo "Cloning phd2 git repo depth=1"
  git clone --depth=1 https://github.com/OpenPHDGuiding/phd2.git phd2

  # Ensure the phd2 build root exists
  mkdir -p "$PHD2_DEPLOY_DIR" || {
      echo "Failed to create phd2 build directory: $PHD2_DEPLOY_DIR"
      exit 1
  }

  # Ensure the phd2 build root exists
  cd "$PHD2_DEPLOY_DIR" || {
      echo "Failed to enter phd2 build directory: $PHD2_DEPLOY_DIR"
      exit 1
  }
  
  echo "Configuring and building phd2"

  cmake -DUSE_SYSTEM_LIBINDI=1 -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release "$ROOTDIR/phd2" || { echo "PHD2 configuration failed"; exit 1; }
  make -j $JOBS || { echo "PHD2 compilation failed"; exit 1; }
  sudo make install || { echo "PHD2 installation failed"; exit 1; }

  cd "$ROOTDIR"
else
  echo "Skipping PHD2 installation"
fi

sudo ldconfig

echo "Installation completed successfully!"
