# INDI Stable Build Scripts

A collection of scripts to build and install INDI (Instrument-Neutral Distributed Interface) core, 3rd party drivers, and related astronomy software from source with stable versions.

## Overview

These scripts provide a streamlined way to build and install:
- **INDI Core** - The main INDI server and library
- **INDI 3rd Party Drivers** - Device-specific drivers (all or selective)
- **LibXISF** - XISF file format support library
- **StellarSolver** - Astronomical image solving library
- **KStars** - Desktop planetarium and observation planning
- **PHD2** - Auto-guiding software

## Files

- `build-indi-stable.sh` - Main build script
- `3rd-party-drivers.txt` - Example file for selective driver installation
- `indi-dependencies.sh` - System dependencies installation script
- `README.md` - This documentation file

## Quick Start

### 1. Install Dependencies
```bash
# Run the dependencies script first
./indi-dependencies.sh
```

### 2. Basic Installation

```bash
# Install INDI core + all 3rd party drivers + LibXISF
./build-indi-stable.sh
```

### 3. Selective Installation

```bash
# Install only specific drivers from list
./build-indi-stable.sh --3rdparty 3rd-party-drivers.txt

# Install without LibXISF
./build-indi-stable.sh --no-libxisf

# Install additional software
./build-indi-stable.sh --kstars --stellasolver --phd2
```

## Script Options

Main Build Script (build-indi-stable.sh)

```bash
# Basic options
--no-libxisf          Skip LibXISF installation
--no-indi             Skip INDI core installation
--no-3rdparty         Skip all 3rd party drivers
--3rdparty FILE       Install only drivers from text file

# Additional software
--stellasolver        Install StellarSolver
--kstars              Install KStars
--phd2 [VERSION]      Install PHD2 (optional version)

# Help
--help                Show usage information
```

## Dependencies Script (`indi-dependencies.sh`)

Installs all required system dependencies for INDI and related software.

## 3rd Party Drivers File Format

Create a 3rd-party-drivers.txt file with one driver per line:

```txt
# Libs
liasi
libatik

# Camera drivers
indi-asi
indi-atik

# Telescope drivers
indi-eqmod
```

## Usage Examples

### Example 1: Minimal Installation
```bash
# Only INDI core (no drivers, no LibXISF)
./build-indi-stable.sh --no-libxisf --no-3rdparty
```

### Example 2: Custom Driver Selection
```bash
# Install only specific drivers
./build-indi-stable.sh --3rdparty my-custom-drivers.txt
```

### Example 3: Full Astronomy Suite
```bash
# Install everything
./build-indi-stable.sh --kstars --stellasolver --phd2
```

### Example 4: Specific PHD2 Version
```bash
# Install with specific PHD2 version
./build-indi-stable.sh --phd2 v2.6.11
```

## Configuration

### Build Directory

The scripts uses `~/Projects/indi-build-stable` as the build directory by default. You can override this:
```bash
export BUILD_DIR=/custom/path
./build-indi-stable.sh
```

### Compiler Flags
The scripts use optimized compiler flags:
```bash
export CFLAGS="-march=native -w -Wno-psabi -D_FILE_OFFSET_BITS=64"
export CXXFLAGS="-march=native -w -Wno-psabi -D_FILE_OFFSET_BITS=64"
```

## Cleanup and Reinstallation

The scripts automatically clean up previous installations before building. To manually remove everything:
```bash
cd ~/Projects/indi-build-stable # or the custom build dir path
find . -name install_manifest.txt | sudo xargs rm

cd ~/
# Remove all installed files
sudo rm -rf ~/Projects/indi-build-stable
```

## Component Versions
> **Note**: These can be edited in the `build-indi-stable.sh`

| Component         | Default Version                      | Repository                                      |
|-------------------|--------------------------------------|-------------------------------------------------|
| INDI Core         | v2.1.5                               | https://github.com/indi/indi                    |
| INDI 3rd Party    | v2.1.5                               | https://github.com/indi/indi-3rdparty           |
| LibXISF           | v0.2.13                              | https://gitea.nouspiro.space/nou/libXISF        |
| StellarSolver     | 5902126c7a0ac01877c29f1189bda23f0837cf58 | https://github.com/rlancaste/stellarsolver  |
| KStars            | origin/stable-3.7.8                  | https://invent.kde.org/education/kstars         |
| PHD2              | v2.6.12                              | https://github.com/OpenPHDGuiding/phd2          |

## Credits

This project is based on the work by **Dušan Poizl's** `astro-soft-build`:
https://gitea.nouspiro.space/nou/astro-soft-build

The scripts were adapted and enhanced with additional features including:

- Selective driver installation
- Optional component support
- Improved error handling
- Better documentation

## Troubleshooting

### Common Issues

**Missing Dependencies**: Always run `indi-dependencies.sh` first
**Build Failures**: Check available memory (low memory systems may need JOBS=2)
**Permission Issues**: Ensure you have sudo privileges for installation

### Low Memory Systems
For systems with less than 5GB RAM, the script automatically limits parallel jobs to 2.

## License

This project is open source and available under the Apache License Version 2.0.

## Useful Links

### Official Project Websites
- [INDI Official Website](https://www.indilib.org/) - Main INDI project website
- [KStars Official Page](https://edu.kde.org/kstars/) - KStars documentation and information
- [PHD2 Guiding](https://openphdguiding.org/) - Official PHD2 guiding software site

### GitHub Repositories
- [INDI Core](https://github.com/indi/indi) - Main INDI library and server
- [INDI 3rd Party Drivers](https://github.com/indi/indi-3rdparty) - Device-specific drivers
- [LibXISF](https://gitea.nouspiro.space/nou/libXISF) - XISF file format library
- [StellarSolver](https://github.com/rlancaste/stellarsolver) - Astronomical image solving
- [KStars](https://invent.kde.org/education/kstars) - KStars source code
- [PHD2](https://github.com/OpenPHDGuiding/phd2) - Auto-guiding software

### Documentation & Forums
- [INDI Documentation](https://indilib.org/support/tutorials.html) - Tutorials and guides
- [INDI Forum](https://indilib.org/forum.html) - Community support forum
- [KStars User Manual](https://docs.kde.org/stable5/en/kstars/kstars/) - Official documentation
- [PHD2 Documentation](https://openphdguiding.org/manual/) - User manual and guides

### Related Projects
- [Ekos](https://indilib.org/about/ekos.html) - INDI-based observation automation
- [INDI Web Manager](https://github.com/knro/indiwebmanager) - Web-based INDI control
- [ASTAP](https://www.hnsky.org/astap.htm) - Astronomical image solving program

### Community Resources
- [INDI Library GitHub Discussions](https://github.com/indi/indi/discussions) - GitHub discussions
- [Cloudy Nights Forum](https://www.cloudynights.com/forum/75-astro-imaging-software-and-processing/) - Astronomy software discussions
- [Stargazers Lounge](https://stargazerslounge.com/) - Astronomy community forum

> **Note**: These scripts are designed for stable versions. For bleeding-edge development versions, please refer to the respective project repositories.