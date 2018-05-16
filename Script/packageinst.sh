
echo "Installing dependencies with fink"
. /sw/bin/init.sh

declare -a packages=("suitesparse"
                      "fftw3"
                      "libmatio2"
                      "libmatio2-shlibs"
                      "hdf5.9-oldapi" "hdf5.9-oldapi-shlibs"
                      "libpcre1"
                      "ant"
                      "gettext-bin"
                      "gettext-tools"
                      "arpack-ng"
                      "pkgconfig"
                      "libcurl4"
                      "libmatio2")
for i in "${packages[@]}"
do
   clear
   echo " Installing  $i"
   sudo fink install $i
done
count=0
installed=""
ninstalled=""
listi=$(fink list -i)

for i in "${packages[@]}"
do
   if [ -z "${listi##*$i*}" ] ; then
     installed="$installed \n $i"
   else
     count=`expr $count + 1`
     ninstalled="$ninstalled \n $i"
   fi
done

clear
echo -e "List of installed packages : $installed \n\n"
if [ $count -gt 0 ] ; then
  echo -e "Following packages were not installed: $ninstalled\n\n Please install them manually"
else
  echo  -e "Congratulations everything is perfectly setup to compile Scilab\n\n"
fi
