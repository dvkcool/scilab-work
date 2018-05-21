#!/bin/sh
# shellcheck disable=SC2155
# shellcheck disable=SC2164
# shellcheck disable=SC1091
# shellcheck disable=SC1117

# Checking if user has root access
if [[ $EUID -ne 0 ]]; then
   echo "You must run this script with root permissions."
   exit 0
fi

# Deleting scilab folder if already present
sudo rm -rf scilab

# Cloning the base repository
git clone git://git.scilab.org/scilab

# Performing svn checkout
cd scilab/scilab

svn checkout --username anonymous --password Scilab svn://svn.scilab.org/scilab/trunk/Dev-Tools/SE/Prerequirements/macosx/bin bin
svn checkout --username anonymous --password Scilab svn://svn.scilab.org/scilab/trunk/Dev-Tools/SE/Prerequirements/macosx/lib lib
svn checkout --username anonymous --password Scilab svn://svn.scilab.org/scilab/trunk/Dev-Tools/SE/Prerequirements/macosx/thirdparty thirdparty
svn checkout --username anonymous --password Scilab svn://svn.scilab.org/scilab/trunk/Dev-Tools/SE/Prerequirements/macosx/include include
svn checkout --username anonymous --password Scilab svn://svn.scilab.org/scilab/trunk/Dev-Tools/SE/Prerequirements/macosx/java java



# Checking out the branch
cd ..

branch_default="6.0"
read -p "Please enter your choice of branch[$branch_default]: " branch
branch="${branch:-$branch_default}"

# Git checkout
git checkout $branch

# Going for compilation

cd scilab

# Initialins fink again just to be sure
. /sw/bin/init.sh
s=""
# Asking about Modelica/ ocaml
echo  "Do you want to compile with ocaml [y/n]"
read t
if [ "$t" = "y" ]; then
  sudo fink install ocaml
  listi=$(fink list -i)
  i="ocaml"
  # checking if listi contains ocaml
     if [ -z "${listi##*$i*}" ] ; then
       echo "ocaml installed"
     else
       echo "ocaml not installed, Please install it manually and rerun the script."
       exit 0
     fi
 else
  s=" $s  --without-modelica"
fi

# Do you want to specify other parameters while compilation
echo "Do you want to specify other parameters while compilation [y/n]"
read t
if [ "$t" = "y" ]; then
  echo "Please enter the other paramters: "
  read t
  s=" $s $t"

# Compiling the default
./configure --without-openmp --without-tk --with-eigen_include=`pwd`/lib/Eigen/includes $s && make

# Installing scilab
make install

# Running scilab
echo "Congratulations Scilab is successfully installed. \n\n To launch Scilanb just type scilab in terminal".


exit 0
