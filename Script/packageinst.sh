
echo "Installing dependencies with fink"
. /sw/bin/init.sh

declare -a packages=("suitesparse"
                      "fftw3"
                      "libmatio2"
                      "libmatio2-shlibs"
                      "hdf5.8" "hdf5.8-shlibs"
                      "libpcre1"
                      "ant"
                      "gettext-bin"
                      "gettext-tools"
                      "arpack-ng"
                      "pkgconfig"
                      "libcurl4"
                      "libmatio2")
#for i in "${packages[@]}"
#do
#   clear
#   echo " Installing  $i"
#   sudo fink install $i -y
#done
c = 0
installed=""
ninstalled=""
listi=$(fink list -i)
for i in "${packages[@]}"
do
   if [ "$listi" = *"$i"* ] ; then
     $installed = $installed + "\n $i"
   else
     c = `expr $c + 1`
     $ninstalled = $ninstalled + "\n $i"
   fi
done

clear
echo "List of installed packages : $installed"
if [ $c -ge 0 ] ; then
  echo "Following packages were not installed"
