# Deploy Astronomy Software on Raspberry Pi 5

Create Projects directory:<br>
`mkdir ~/Projects && cd ~/Projects`

## Stellarsolver
Git Repo: https://github.com/rlancaste/stellarsolver.git
```
git clone https://github.com/rlancaste/stellarsolver.git
cd stellarsolver/linux-scripts
./installStellarSolverTesterQt6.sh
```

## PHD2
Git Repo: https://github.com/OpenPHDGuiding/phd2.git
```
sudo apt-get install build-essential git cmake pkg-config libwxgtk3.2-dev \
   wx-common wx3.2-i18n libindi-dev libnova-dev gettext zlib1g-dev libx11-dev \
   libcurl4-gnutls-dev libopencv-dev libeigen3-dev libgtest-dev

git clone -b release/v2.6.13 --depth 1 https://github.com/OpenPHDGuiding/phd2.git
cd phd2

mkdir -p ~/Projects/phd2/tmp
cd ~/Projects/phd2/tmp
cmake -DUSE_SYSTEM_LIBINDI=1 -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Debug ~/Projects/phd2
make -j4
sudo make install

```

## LibXISF
Git Repo: https://gitea.nouspiro.space/nou/libXISF.git

```
cmake -B build -S .
cmake --build build --parallel
cmake --install build
```

## Indi
Git Repo: https://github.com/indilib/indi.git

## Indi - 3rdParty
Git Repo: https://github.com/indilib/indi-3rdparty.git

## KStars - EKOS
Git Repo: https://invent.kde.org/education/kstars.git


