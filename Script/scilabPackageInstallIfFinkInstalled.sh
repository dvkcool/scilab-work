#!/bin/sh
echo "Installing Scilab dependencies with fink"
. /sw/bin/init.sh

# Checking if user has root access
if [[ $EUID -ne 0 ]]; then
   echo "You must run this script with root permissions."
   exit 0
fi

# An array containing list of packages to install
declare -a packages=("suitesparse"
                      "fftw3"
                      "libmatio2"
                      "libmatio2-shlibs"
                      "hdf5.9" "hdf5.9-shlibs"
                      "libpcre1"
                      "ant"
                      "gettext-bin"
                      "gettext-tools"
                      "arpack-ng"
                      "pkgconfig"
                      "libcurl4"
                      "libmatio2")

# Installing each package one by one
for i in "${packages[@]}"
do
   clear
   echo " Installing  $i"
   fink install $i
done

# A variable to count number of unistalled packages
count=0

# A variable to store list of installed packages
installed=""

# A variable to store list of uninstalled packages
ninstalled=""

# A variable to store a list of all packages installed through fink
listi=$(fink list -i)


for i in "${packages[@]}"
do
# checking if listi contains a package specified
   if [ -z "${listi##*$i*}" ] ; then
     installed="$installed \n $i"
   else
     # Increasing count, if its uninstalled
     count=`expr $count + 1`
     ninstalled="$ninstalled \n $i"
   fi
done

# Clearing screen
clear
echo  "List of installed packages : $installed \n\n"

# If count > 0 then there is a package which is not installed, i.e. Not ready to compile yet
if [ $count -gt 0 ] ; then
  echo  "Following packages were not installed: $ninstalled\n\n Please install them manually"
else
  # All packages are installed and ready to compile
  echo   "Congratulations everything is perfectly setup to compile Scilab\n\n"
fi
