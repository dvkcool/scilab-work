
echo "Installing dependencies with fink"
. /sw/bin/init.sh
echo " Installing  suitesparse"
sudo fink install suitesparse


echo "Installing fftw3 "
sudo fink install fftw3


echo "Installing libmatio2"
sudo fink install libmatio2


echo "Installing libmatio2-shlibs"
sudo fink install libmatio2-shlibs


echo "Installing hdf5.8"
sudo fink install hdf5.8


echo "Installing hdf5.8-shlibs"
sudo fink install hdf5.8-shlibs


echo " Installing libpcre1"
sudo fink install libpcre1


echo "Installing ant"
sudo fink install ant


echo "Installing gettext-bin-0.19.8.1-2"
sudo fink install gettext-bin-0.19.8.1-2


echo "Installing gettext-tools-0.19.8.1-2"
sudo fink install gettext-tools-0.19.8.1-2


echo "Installing arpack-ng-3.4.0-1"
sudo fink install arpack-ng-3.4.0-1


echo "Installing pkgconfig-0.28-2"
sudo fink install pkgconfig-0.28-2


echo "Installing libcurl4-7.57.0-1"
sudo fink install libcurl4-7.57.0-1


echo "Installing libmatio2-1.5.3-1"
sudo fink install libmatio2-1.5.3-1
