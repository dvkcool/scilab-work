
echo "Installing dependencies with fink"
. /sw/bin/init.sh
echo " Installing  suitesparse"
s1=$(sudo fink install suitesparse)
echo "$s1"
if [ "$s1" = "No packages to install." ] ; then
  echo "suitesparse is already installed"
else
  echo "not installed"
fi

#echo "Installing fftw3"
#sudo fink install fftw3


#echo "Installing libmatio2"
#sudo fink install libmatio2


#echo "Installing libmatio2-shlibs"
#sudo fink install libmatio2-shlibs


#echo "Installing hdf5.8"
#sudo fink install hdf5.8


#echo "Installing hdf5.8-shlibs"
#sudo fink install hdf5.8-shlibs


#echo " Installing libpcre1"
#sudo fink install libpcre1


#echo "Installing ant"
#sudo fink install ant


#echo "Installing gettext-bin"
#sudo fink install gettext-bin


#echo "Installing gettext-tools"
#sudo fink install gettext-tools


#echo "Installing arpack-ng"
#sudo fink install arpack-ng


#echo "Installing pkgconfig"
#sudo fink install pkgconfig


#echo "Installing libcurl4"
#sudo fink install libcurl4


#echo "Installing libmatio2"
#sudo fink install libmatio2
