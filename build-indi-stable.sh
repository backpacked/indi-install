#!/bin/bash

# Set compiler flags
export CFLAGS="-march=native -w -Wno-psabi -D_FILE_OFFSET_BITS=64"
export CXXFLAGS="-march=native -w -Wno-psabi -D_FILE_OFFSET_BITS=64"

# Get the script's directory
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
LIBXISF_COMMIT="v0.2.13"
INDI_COMMIT="v2.1.5"
INDI_3RD_COMMIT="v2.1.5"
STELLAR_COMMIT="5902126c7a0ac01877c29f1189bda23f0837cf58"
KSTARS_COMMIT="origin/stable-3.7.8"
PHD_COMMIT="v2.6.12"

INSTALL_INDI=true
INSTALL_LIBXISF=true
INSTALL_3RDPARTY=true
INSTALL_ALL_3RDPARTY=true
INSTALL_STELLAR=false
INSTALL_KSTARS=false
INSTALL_PHD=false
LIBS_LIST_FILE=""

# Function to display usage
usage() {
  echo "Usage: $0 [OPTIONS]"
  echo "Options:"
  echo "  --no-libxisf          Skip LibXISF installation"
  echo "  --no-indi             Skip Indi installation"
  echo "  --3rdparty FILE       Install only drivers from FILE (one per line)"
  echo "  --no-3rdparty         Skip all 3rd party drivers installation"
  echo "  --stellasolver        Install stellarsolver"
  echo "  --kstars              Install KStars"
  echo "  --phd2 [VERSION]      Install PHD2 (optional: specify version, default: v2.6.12)"
  echo "  --help                Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0                             # Install INDI + LibXISF + all 3rd party (default)"
  echo "  $0 --no-libxisf                # Install INDI + all 3rd party (no LibXISF)"
  echo "  $0 --3rdparty my_drivers.txt   # Install only specific drivers"
  echo "  $0 --no-3rdparty               # Install only INDI core (no 3rd party)"
  echo "  $0 --stellasolver --kstars     # Install INDI + stellarsolver + KStars"
  echo "  $0 --phd2 v2.6.11              # Install INDI + PHD2 with specific version"
  echo "  $0 --kstars --phd2             # Install INDI + KStars + PHD2"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --no-libxisf)
      INSTALL_LIBXISF=false
      shift
      ;;
    --no-indi)
      INSTALL_INDI=false
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
    --no-3rdparty)
      INSTALL_3RDPARTY=false
      INSTALL_ALL_3RDPARTY=false
      shift
      ;;
    --stellasolver)
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
    --help)
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
ROOTDIR="$BUILD_DIR/indi-build-stable"

JOBS=$(grep -c ^processor /proc/cpuinfo)

# 64 bit systems need more memory for compilation
if [ $(getconf LONG_BIT) -eq 64 ] && [ $(grep MemTotal < /proc/meminfo | cut -f 2 -d ':' | sed s/kB//) -lt 5000000 ]
then
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
      sudo apt -y install qtbase5-dev wcslib-dev libcfitsio-dev libgsl-dev
      ;;
    phd2)
      echo "Installing system dependencies for PHD2..."
      sudo apt -y install libwxgtk3.2-dev libeigen3-dev
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

  if [ ! -d "$target_dir/.git" ]; then
    echo "Cloning $repo_url into $target_dir at $commit..."
    git clone --depth=1 "$repo_url" "$target_dir" || { echo "Failed to clone $repo_url"; exit 1; }
    cd "$target_dir" || exit 1
  else
    echo "Updating $target_dir to $commit..."
    cd "$target_dir" || { echo "Failed to cd into $target_dir"; exit 1; }
    git fetch --all --tags --prune --depth=1 || { echo "Failed to fetch from $repo_url"; exit 1; }
  fi

  # Detect commit type
  if git rev-parse --verify --quiet "$commit^{commit}" >/dev/null 2>&1; then
    # Commit SHA
    echo "Checking out commit SHA $commit..."
    git checkout --detach "$commit"
  elif git show-ref --verify --quiet "refs/tags/$commit"; then
    # Tag
    echo "Checking out tag $commit..."
    git checkout "tags/$commit" -b "tag-$commit" || git checkout "tags/$commit"
  elif git show-ref --verify --quiet "refs/remotes/$commit"; then
    # Remote branch (e.g., origin/stable-3.7.8)
    branch="${commit#origin/}"
    echo "Checking out branch $branch from origin..."
    git checkout -B "$branch" "$commit"
  else
    echo "Warning: Could not resolve $commit in $repo_url"
    exit 1
  fi

  cd "$ROOTDIR"
}


# Install LibXISF if requested
if [ "$INSTALL_LIBXISF" = true ]; then
  echo "Cleaning up previous LibXISF installations..."
  [ -f build-libXISF/install_manifest.txt ] && echo "Deleting libXISF"; cat build-libXISF/install_manifest.txt | sudo xargs rm -f
  
  echo "Installing LibXISF..."
  gitclone "https://gitea.nouspiro.space/nou/libXISF.git" "$LIBXISF_COMMIT"
  
  [ ! -d ../build-libXISF ] && { cmake -B ../build-libXISF ../libXISF -DCMAKE_BUILD_TYPE=Release -DUSE_BUNDLED_ZLIB=OFF || { echo "LibXISF configuration failed"; exit 1; } }
  cd ../build-libXISF
  make -j $JOBS || { echo "LibXISF compilation failed"; exit 1; }
  sudo make install || { echo "LibXISF installation failed"; exit 1; }
  cd "$ROOTDIR"
else
  echo "Skipping LibXISF installation as requested"
fi

# Install INDI core if requested
if [ "$INSTALL_INDI" = "true" ]; then
  echo "Cleaning up previous INDI installations..."
  [ -f build-indi/install_manifest.txt ] && echo "Deleting INDI"; cat build-indi/install_manifest.txt | sudo xargs rm -f

  # Install Dependencies
  install_deps indi

  echo "Installing INDI core..."
  gitclone "https://github.com/indilib/indi.git" "$INDI_COMMIT"

  [ ! -d ../build-indi ] && { cmake -B ../build-indi ../indi -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release || { echo "INDI configuration failed"; exit 1; } }
  cd ../build-indi
  make -j $JOBS || { echo "INDI compilation failed"; exit 1; }
  sudo make install || { echo "INDI installation failed"; exit 1; }
  cd "$ROOTDIR"
else
  echo "Skipping Indi Server installation as requested"
fi

# Install INDI 3rd party libraries and drivers if requested
if [ "$INSTALL_3RDPARTY" = true ]; then
  3RD_PARTY_BUILD_DIR="$ROOTDIR/build-indi-3rdparty"

  # Cleanup 3rd party builds
  if [ -d "$3RD_PARTY_BUILD_DIR" ]; then
      echo "Cleaning up 3rd party builds..."
      find "$3RD_PARTY_BUILD_DIR" -name "install_manifest.txt" -exec cat {} \; | sudo xargs rm -f 2>/dev/null || true
  fi

  # Install Dependencies
  install_deps indi-3rdparty

  echo "Installing INDI 3rd party..."
  gitclone "https://github.com/indilib/indi-3rdparty.git" "$INDI_3RD_COMMIT"
  
  if [ "$INSTALL_ALL_3RDPARTY" = true ]; then
    # Build all 3rd party drivers
    echo "Building all INDI 3rd party drivers..."
    mkdir -p "$3RD_PARTY_BUILD_DIR"
    cd "$3RD_PARTY_BUILD_DIR"
    
    cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release "$ROOTDIR/indi-3rdparty" || { echo "INDI 3rdparty configuration failed"; exit 1; }
    make -j $JOBS || { echo "INDI 3rd-party compilation failed"; exit 1; }
    sudo make install || { echo "INDI 3rdparty installation failed"; exit 1; }
  else
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
          
          # Check if driver directory exists
          if [ ! -d "$3RD_PARTY_BUILD_DIR/$driver" ]; then
              echo "Driver directory $driver not found in indi-3rdparty, skipping..."
              continue
          fi
          
          # Create build directory for this driver
          build_dir="$3RD_PARTY_BUILD_DIR/$driver"
          mkdir -p "$build_dir"
          cd "$build_dir"
          
          # Configure and build the driver
          cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release "$ROOTDIR/indi-3rdparty/$driver" || { echo "Configuration failed for $driver"; continue; }
          make -j $JOBS || { echo "Compilation failed for $driver"; continue; }
          sudo make install || { echo "Installation failed for $driver"; continue; }
      done
    fi
  fi
  cd "$ROOTDIR"
else
  echo "Skipping INDI 3rd party installation as requested"
fi

# Install stellarsolver if requested
if [ "$INSTALL_STELLAR" = true ]; then
  echo "Cleaning up previous stellarsolver installations..."
  [ -f build-stellarsolver/install_manifest.txt ] && echo "Deleting stellarsolver"; cat build-stellarsolver/install_manifest.txt | sudo xargs rm -f
  
  # Install Dependencies
  install_deps stellarsolver
  
  echo "Installing stellarsolver..."
  gitclone "https://github.com/rlancaste/stellarsolver.git" "$STELLAR_COMMIT"

  [ ! -d ../build-stellarsolver ] && { cmake -B ../build-stellarsolver ../stellarsolver -DCMAKE_BUILD_TYPE=Release || { echo "Stellarsolver configuration failed"; exit 1; } }
  cd ../build-stellarsolver
  make -j $JOBS || { echo "Stellarsolver compilation failed"; exit 1; }
  sudo make install || { echo "Stellarsolver installation failed"; exit 1; }
  cd "$ROOTDIR"
else
  echo "Skipping stellarsolver installation"
fi

# Install KStars if requested
if [ "$INSTALL_KSTARS" = true ]; then
  echo "Cleaning up previous KStars installations..."
  [ -f build-kstars/install_manifest.txt ] && echo "Deleting KStars"; cat build-kstars/install_manifest.txt | sudo xargs rm -f
  
  # Install Dependencies
  install_deps kstars

  echo "Installing KStars..."
  gitclone "https://invent.kde.org/education/kstars.git" "$KSTARS_COMMIT"

  [ ! -d ../build-kstars ] && { cmake -B ../build-kstars -DBUILD_TESTING=Off ../kstars -DCMAKE_BUILD_TYPE=Release || { echo "KStars configuration failed"; exit 1; } }
  cd ../build-kstars
  make -j $JOBS || { echo "KStars compilation failed"; exit 1; }
  sudo make install || { echo "KStars installation failed"; exit 1; }
  cd "$ROOTDIR"
else
  echo "Skipping KStars installation"
fi

# Install PHD2 if requested
if [ "$INSTALL_PHD" = true ]; then
  echo "Cleaning up previous PHD2 installations..."
  [ -f build-phd2/install_manifest.txt ] && echo "Deleting PHD2"; cat build-phd2/install_manifest.txt | sudo xargs rm -f

  # Install Dependencies
  install_deps phd2
  
  echo "Installing PHD2 ($PHD_COMMIT)..."
  gitclone "https://github.com/OpenPHDGuiding/phd2.git" "phd2" "$PHD_COMMIT"


  [ ! -d ../build-phd2 ] && cmake -B ../build-phd2 -DCMAKE_BUILD_TYPE=Release || { echo "PHD2 configuration failed"; exit 1; }
  cd ../build-phd2
  make -j $JOBS || { echo "PHD2 compilation failed"; exit 1; }
  sudo make install || { echo "PHD2 installation failed"; exit 1; }
else
  echo "Skipping PHD2 installation"
fi

sudo ldconfig

echo "Installation completed successfully!"
