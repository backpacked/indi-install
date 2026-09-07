#!/bin/bash

# Set compiler flags
export CFLAGS="-march=native -w -Wno-psabi -D_FILE_OFFSET_BITS=64"
export CXXFLAGS="-march=native -w -Wno-psabi -D_FILE_OFFSET_BITS=64"

# Get the script's directory
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
LIBXISF_COMMIT="v0.2.13"
INDI_COMMIT="v2.2.4"
INDI_3RD_COMMIT="v2.2.4"
STELLAR_COMMIT="2.8"
KSTARS_COMMIT="v2.9.8"
PHD_COMMIT="v2.6.14"

INSTALL_INDI=false
INSTALL_LIBXISF=false
INSTALL_3RDPARTY=false
INSTALL_ALL_3RDPARTY=false
INSTALL_STELLAR=false
INSTALL_KSTARS=false
INSTALL_PHD=false
LIBS_LIST_FILE=""

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
  echo "  --indi                Install Indi"
  echo "  --libxisf             Install LibXISF"
  echo "  --3rdparty FILE       Install only drivers from FILE (one per line)"
  echo "  --no-3rdparty         Skip all 3rd party drivers installation"
  echo "  --all-3rdparty        Install all 3rd-party drivers"
  echo "  --stellarsolver       Install stellarsolver"
  echo "  --kstars              Install KStars"
  echo "  --phd2 [VERSION]      Install PHD2 (optional: specify version, default: v2.6.12)"
  echo "  --all                 Install Everything"
  echo "  --help                Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0                                    # Show Usage"
  echo "  $0 --indi                             # Install INDI"
  echo "  $0 --libxisf                          # Install LibXISF"
  echo "  $0 --3rdparty my_drivers.txt          # Install only specific drivers"
  echo "  $0 --no-3rdparty                      # Do not install 3rd party"
  echo "  $0 --all-3rdparty                     # Install all 3rd-party drivers"
  echo "  $0 --indi --stellarsolver --kstars    # Install INDI + stellarsolver + KStars"
  echo "  $0 --phd2 v2.6.11                     # Install INDI + PHD2 with specific version"
  echo "  $0 --indi --kstars --phd2             # Install INDI + KStars + PHD2"
  echo "  $0 --all                              # Install INDI + liXISF+ all-3rd-party + stellarsolver + KStars + PHD2"
}

# Show usage and exit if no arguments were provided
if [[ $# -eq 0 ]]; then
  usage
  exit 0
fi

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --indi)
      INSTALL_INDI=true
      shift
      ;;
    --3rdparty)
      if [[ -n "$2" && ! "$2" =~ ^-- ]]; then
          LIBS_LIST_FILE="$2"
          INSTALL_3RDPARTY=true
          INSTALL_ALL_3RDPARTY=false
          shift 2
      else
          echo "Error: --3rdparty requires a filename argument"
          exit 1
      fi
      ;;
    --libxisf)
      INSTALL_LIBXISF=true
      shift
      ;;
    --no-3rdparty)
      INSTALL_3RDPARTY=false
      INSTALL_ALL_3RDPARTY=false
      shift
      ;;
    --all-3rdparty)
      INSTALL_3RDPARTY=false
      INSTALL_ALL_3RDPARTY=true
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
      # Check if next argument is a version (doesn't start with --)
      if [[ -n "$2" && ! "$2" =~ ^-- ]]; then
          PHD_COMMIT="$2"
          shift 2
      else
          shift
      fi
      ;;
    --all)
      INSTALL_INDI=true
      INSTALL_LIBXISF=true
      INSTALL_ALL_3RDPARTY=true
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

# Validate libs list file if provided for selective installation
if [[ -n "$LIBS_LIST_FILE" ]]; then
  # Check if file exists in script directory
  if [[ -f "$SCRIPT_ROOT/$LIBS_LIST_FILE" ]]; then
    LIBS_LIST_FILE="$SCRIPT_ROOT/$LIBS_LIST_FILE"
  elif [[ ! -f "$LIBS_LIST_FILE" ]]; then
    # Check if it's an absolute path or relative to current directory
    if [[ ! -f "$LIBS_LIST_FILE" ]]; then
      echo "Error: Libs/drivers list file '$LIBS_LIST_FILE' not found!"
      echo "Searched in:"
      echo "  - Script directory: $SCRIPT_ROOT/$LIBS_LIST_FILE"
      echo "  - Current directory: $(pwd)/$LIBS_LIST_FILE"
      echo "  - Absolute path: $LIBS_LIST_FILE"
      exit 1
    fi
  fi
fi

BUILD_DIR=${BUILD_DIR:-$HOME/Projects}
ROOTDIR="$BUILD_DIR/indi-build"

JOBS=$(grep -c ^processor /proc/cpuinfo)

# 64 bit systems need more memory for compilation
if [ $(getconf LONG_BIT) -eq 64 ] && [ $(grep MemTotal < /proc/meminfo | cut -f 2 -d ':' | sed s/kB//) -lt 5000000 ]; then
    echo "Low memory limiting to JOBS=2"
    JOBS=2
  fi

[ ! -d "$BUILD_DIR" ] && mkdir -p "$BUILD_DIR"
[ ! -d "$ROOTDIR" ] && mkdir -p "$ROOTDIR"
cd "$ROOTDIR"

# Install required system dependencies
install_deps() {
  local component=$1

  sudo apt update && sudo apt upgrade -y

  case "$component" in
    indi|indi-3rdparty)
      echo "Installing system dependencies for INDI Core and INDI 3rd party..."
      sudo apt-get -y install libnova-dev libcfitsio-dev libusb-1.0-0-dev zlib1g-dev libgsl-dev build-essential cmake git \
          libjpeg-dev libcurl4-gnutls-dev libtiff-dev libfftw3-dev libftdi-dev libgps-dev libraw-dev libdc1394-dev libgphoto2-dev \
          libboost-dev libboost-regex-dev librtlsdr-dev liblimesuite-dev libftdi1-dev libavcodec-dev libavdevice-dev libzmq3-dev libudev-dev \
          cdbs dkms fxload libkrb5-dev libtheora-dev libindi-dev libev-dev

      ;;
    kstars)
      echo "Installing system dependencies for KStars..."
      sudo apt -y install build-essential cmake git libstellarsolver-dev libeigen3-dev libcfitsio-dev zlib1g-dev extra-cmake-modules \
        libkf5plotting-dev libqt5svg5-dev libkf5xmlgui-dev libkf5kio-dev kinit-dev libkf5newstuff-dev libkf5doctools-dev \
        libkf5notifications-dev qtdeclarative5-dev libkf5crash-dev gettext libnova-dev libgsl-dev libraw-dev libkf5notifyconfig-dev \
        wcslib-dev libqt5websockets5-dev xplanet xplanet-images qt5keychain-dev libsecret-1-dev breeze-icon-theme libqt5datavisualization5-dev
      ;;
    stellarsolver)
      echo "Installing system dependencies for StellarSolver..."
      sudo apt -y install g++ git cmake qt6-base-dev libgl1-mesa-dev libcfitsio-dev libgsl-dev wcslib-dev
      ;;
    phd2)
      echo "Installing system dependencies for PHD2..."
      sudo apt-get -y install build-essential git cmake pkg-config libwxgtk3.2-dev wx-common wx3.2-i18n libindi-dev libnova-dev gettext \
        zlib1g-dev libx11-dev libcurl4-gnutls-dev libopencv-dev libeigen3-dev libgtest-dev
      ;;
    *)
      echo "Unknown component: $component"
      ;;
  esac
}

gitfunction() {
  local repo_url=$1
  local target_dir=$2
  local commit=$3

  echo "Working directory:"
  pwd

  if [ ! -d "$target_dir/.git" ]; then
    echo "Cloning $repo_url into $target_dir at $commit..."
    git clone --branch "$commit" --depth=1 "$repo_url" "$target_dir" || { echo "Failed to clone $repo_url"; exit 1; }
    return
  fi

  echo "Updating $target_dir to $commit..."
  cd "$target_dir" || { echo "Failed to cd into $target_dir"; exit 1; }

  # If it's a tag (matches remote tag list) → use your requested fetch style
  if git ls-remote --tags origin | grep -q "refs/tags/$commit$"; then
    git fetch --depth=1 origin tag "$commit" || { echo "Failed to fetch tag $commit from $repo_url"; exit 1; }
    git checkout "$commit" || { echo "Failed to checkout $commit in $target_dir"; exit 1; }

  # Commit SHA or local branch/tag name
  else
    git fetch --depth=1 origin "$commit" || git fetch --depth=1 --tags origin
    git checkout --detach "$commit" 2>/dev/null || git checkout "$commit" || { echo "Failed to checkout $commit in $target_dir"; exit 1; }
  fi
}


# Install LibXISF if requested
if [ "$INSTALL_LIBXISF" = true ]; then
  cd "$ROOTDIR"

  echo "Installing LibXISF..."
  gitfunction "${LIBXISF_GIT}" "libXISF" "$LIBXISF_COMMIT"
  
  cmake -B build -DUSE_BUNDLED_ZLIB=OFF -S .
  cmake --build build --parallel
  sudo cmake --install build

  cd "$ROOTDIR"

  echo "Clean Up"
  rm -rf libXISF

else
  echo "Skipping LibXISF installation"
fi

# Install INDI core if requested
if [ "$INSTALL_INDI" = "true" ]; then
  cd "$ROOTDIR"

  # Install Dependencies
  install_deps indi

  echo "Installing INDI core..."
  gitfunction "${INDI_CORE_GIT}" "indi" "$INDI_COMMIT"

  cmake -B build -G Ninja -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release
  cmake --build build
  sudo cmake --install build

  cd "$ROOTDIR"
else
  echo "Skipping Indi Server installation"
fi

# Install INDI 3rd party libraries and drivers if requested
if [ "$INSTALL_3RDPARTY" = true ]; then
  cd "$ROOTDIR"
  THIRD_PARTY_BUILD_DIR="$ROOTDIR/build-indi-3rdparty"

  # # Cleanup 3rd party builds
  # if [ -d "$THIRD_PARTY_BUILD_DIR" ]; then
  #     echo "Cleaning up 3rd party builds from $THIRD_PARTY_BUILD_DIR"
  #     find "$THIRD_PARTY_BUILD_DIR" -name "install_manifest.txt" -exec cat {} \; | sudo xargs rm -f 2>/dev/null || true
  # fi

  # Install Dependencies
  install_deps indi-3rdparty

  echo "Installing INDI 3rd party..."
  gitfunction "${INDI_3RDPARTY_GIT}" "indi-3rdparty" "$INDI_3RD_COMMIT"

  # Build only selected drivers from file
  echo "Building selected drivers from $LIBS_LIST_FILE..."
  # Read the list of drivers to build
  selected_drivers=()

  while IFS= read -r line || [[ -n "$line" ]]; do
      # Skip comments and empty lines
      [[ "$line" =~ ^#.*$ ]] || [[ -z "$line" ]] && continue
      selected_drivers+=("$line")
  done < "$LIBS_LIST_FILE"
    
  if [ ${#selected_drivers[@]} -eq 0 ]; then
    echo "No valid drivers found in $LIBS_LIST_FILE"
  else
    echo "Selected drivers: ${selected_drivers[*]}"
    
    # Build each selected driver individually
    for driver in "${selected_drivers[@]}"; do
        echo "Building driver: $driver"

        driver_dir="$THIRD_PARTY_BUILD_DIR/$driver"
        source_dir="$ROOTDIR/indi-3rdparty/$driver"

        # Ensure build directory exists
        if [ ! -d "$driver_dir" ]; then
            echo "Driver build directory not found. Creating: $driver_dir"
            mkdir -p "$driver_dir" || { echo "Failed to create $driver_dir"; continue; }
        fi

        # Check source directory exists (required for cmake)
        if [ ! -d "$source_dir" ]; then
            echo "Warning: Source directory not found for $driver → $source_dir"
            echo "Skipping since no source to build from."
            continue
        fi

        cd "$driver_dir" || { echo "Failed to enter $driver_dir"; continue; }

        echo "Working Directory:"
        pwd

        # Configure and build the driver
        cmake  -DINDI_BUILD_UNITTESTS=FALSE -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release "$source_dir" \
          || { echo "Configuration failed for $driver"; continue; }

        make -j "$JOBS" || { echo "Compilation failed for $driver"; continue; }

        sudo make install || { echo "Installation failed for $driver"; continue; }
    done

  fi
  cd "$ROOTDIR"
  rm -rf indi-3rdparty
else
  echo "Skipping custom INDI 3rd party installation"
fi

# Build all 3rd-party drivers if requested
if [ "$INSTALL_ALL_3RDPARTY" = true ]; then
  echo "Building all INDI 3rd-party drivers..."

  cd "$ROOTDIR"
  THIRD_PARTY_BUILD_DIR="$ROOTDIR/build-indi-3rdparty"

  # Cleanup 3rd party builds
  if [ -d "$THIRD_PARTY_BUILD_DIR" ]; then
      echo "Cleaning up 3rd party builds..."
      find "$THIRD_PARTY_BUILD_DIR" -name "install_manifest.txt" -exec cat {} \; | sudo xargs rm -f 2>/dev/null || true
  fi

  # Verify the source directory exists
  if [ ! -d "$ROOTDIR/indi-3rdparty" ]; then
      echo "Source directory indi-3rdparty not found in $ROOTDIR."
      echo "Cannot proceed with building all 3rd-party drivers."
      exit 1
  fi

  # Ensure the 3rd-party build root exists
  mkdir -p "$THIRD_PARTY_BUILD_DIR" || {
      echo "Failed to create 3rd-party build directory: $THIRD_PARTY_BUILD_DIR"
      exit 1
  }

  cd "$THIRD_PARTY_BUILD_DIR" || {
      echo "Failed to enter 3rd-party build directory: $THIRD_PARTY_BUILD_DIR"
      exit 1
  }

  echo "Configuring and building all drivers in indi-3rdparty..."

  # Configure the build
  cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release "$ROOTDIR/indi-3rdparty" \
      || { echo "CMake configuration failed for indi-3rdparty"; exit 1; }

  # Compile
  make -j "$JOBS" || { echo "Compilation failed for indi-3rdparty"; exit 1; }

  # Install
  sudo make install || { echo "Installation failed for indi-3rdparty"; exit 1; }

  echo "All INDI 3rd-party drivers built and installed successfully."

  cd "$ROOTDIR"
  rm -rf indi-3rdparty
  else
    echo "Skipping All INDI 3rd party installation"
fi


# Install stellarsolver if requested
if [ "$INSTALL_STELLAR" = true ]; then
  cd "$ROOTDIR"

  # echo "Cleaning up previous stellarsolver installations..."
  # [ -f build-stellarsolver/install_manifest.txt ] && echo "Deleting stellarsolver"; cat build-stellarsolver/install_manifest.txt | sudo xargs rm -f
  
  # Install Dependencies
  # install_deps stellarsolver
  
  echo "Installing stellarsolver..."
  gitfunction "${STELLAR_GIT}" "stellarsolver" "$STELLAR_COMMIT"

  cd $ROOTDIR/stellarsolver/linux-scripts
  ./installStellarSolverTesterQt6.sh

  # [ ! -d ../build-stellarsolver ] && { cmake -B ../build-stellarsolver ../stellarsolver -DCMAKE_BUILD_TYPE=Release || { echo "Stellarsolver configuration failed"; exit 1; } }
  # cd ../build-stellarsolver
  # make -j $(expr $(nproc) + 2) || { echo "Stellarsolver compilation failed"; exit 1; }
  # sudo make install || { echo "Stellarsolver installation failed"; exit 1; }

  cd "$ROOTDIR"

else
  echo "Skipping stellarsolver installation"
fi

# Install KStars if requested
if [ "$INSTALL_KSTARS" = true ]; then
  cd "$ROOTDIR"
  KSTARS_BUILD_DIR=$ROOTDIR/build_kstars

  # echo "Cleaning up previous KStars installations..."
  # [ -f build-kstars/install_manifest.txt ] && echo "Deleting KStars"; cat build-kstars/install_manifest.txt | sudo xargs rm -f
  
  # Install Dependencies
  install_deps kstars

  echo "Installing KStars..."
  gitfunction "${KSTARS_GIT}" "kstars" "$KSTARS_COMMIT"

  # Ensure the kstars build root exists
  mkdir -p "$KSTARS_BUILD_DIR" || {
      echo "Failed to create kstars build directory: $KSTARS_BUILD_DIR"
      exit 1
  }

  # Ensure the kstars build root exists
  cd "$KSTARS_BUILD_DIR" || {
      echo "Failed to enter kstars build directory: $KSTARS_BUILD_DIR"
      exit 1
  }

  cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo "$ROOTDIR/kstars" || { echo "KStars configuration failed"; exit 1; }
  make -j $JOBS || { echo "KStars compilation failed"; exit 1; }
  sudo make install || { echo "KStars installation failed"; exit 1; }
  cd "$ROOTDIR"

else
  echo "Skipping KStars installation"
fi

# Install PHD2 if requested
if [ "$INSTALL_PHD" = true ]; then
  cd "$ROOTDIR"
  PHD2_BUILD_DIR=$ROOTDIR/build_phd2

  # Cleanup phd2 installs
  # if [ -d "$PHD2_BUILD_DIR" ]; then
  #     echo "Cleaning up previous PHD2 installations..."
  #     find "$PHD2_BUILD_DIR" -name "install_manifest.txt" -exec cat {} \; | sudo xargs rm -f 2>/dev/null || true
  # fi

  # Install Dependencies
  install_deps phd2
  
  echo "Installing PHD2 ($PHD_COMMIT)..."
  gitfunction "${PHD2_GIT}" "phd2" "$PHD_COMMIT"

  # Ensure the phd2 build root exists
  mkdir -p "$PHD2_BUILD_DIR" || {
      echo "Failed to create phd2 build directory: $PHD2_BUILD_DIR"
      exit 1
  }

  # Ensure the phd2 build root exists
  cd "$PHD2_BUILD_DIR" || {
      echo "Failed to enter phd2 build directory: $PHD2_BUILD_DIR"
      exit 1
  }
  
  echo "Configuring and building phd2"

  cmake -DUSE_SYSTEM_LIBINDI=1 -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release "$ROOTDIR/phd2" || { echo "PHD2 configuration failed"; exit 1; }
  make -j $JOBS || { echo "PHD2 compilation failed"; exit 1; }
  sudo make install || { echo "PHD2 installation failed"; exit 1; }

  cd "$ROOTDIR"
  rm -rf phd2

else
  echo "Skipping PHD2 installation"
fi

sudo ldconfig

echo "Installation completed successfully!"
